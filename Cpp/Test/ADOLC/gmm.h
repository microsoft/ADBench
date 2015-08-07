#pragma once

#include <cmath>
#include "adolc/adolc.h"
#include "../defs.h"

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// d dim
// k number of gaussians
// n number of points
// alphas k logs of mixture weights (unnormalized), so
//			weights = exp(log_alphas) / sum(exp(log_alphas))
// means d*k component means
// icf (d*(d+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first d params
// wishart wishart distribution parameters
// x d*n points
// err 1 output
// To generate params in MATLAB given covariance C :
//           L = inv(chol(C, 'lower'));
//           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
template<typename T>
void gmm_objective(int d, int k, int n, const T* const alphas, const T* const means,
	const T* const icf, const double* const x, Wishart wishart, T* err);

// split of the outer loop
template<typename T>
void gmm_objective_split_inner(int d, int k,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const double* const x,
  Wishart wishart,
  T* err);
template<typename T>
void gmm_objective_split_other(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  Wishart wishart,
  T* err);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

// This throws error on n<1
template<typename T>
T arr_max(int n, const T* const x)
{
	T m = x[0];
	for (int i = 1; i < n; i++)
	{
		m = fmax(m, x[i]);
	}
	return m;
}

template<typename T>
T logsumexp(int n, const T* const x)
{
	T mx = arr_max(n, x);
	T semx = 0.;
	for (int i = 0; i < n; i++)
	{
		semx += exp(x[i] - mx);
	}
	return log(semx) + mx;
}

double log_gamma_distrib(double a, double p)
{
  double out = 0.25 * p * (p - 1) * log(PI);
	for (int j = 1; j <= p; j++)
	{
		out += lgamma(a + 0.5*(1 - j));
	}
	return out;
}

// p dim
// k number of components
// wishart parameters
// icf  (p*(p+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first p params
template<typename T>
T log_wishart_prior(int p, int k, Wishart wishart,
	const T* const icf)
{
	int n = p + wishart.m + 1;
	int icf_sz = p*(p + 1) / 2;

	double C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

	T out = 0;
	for (int ik = 0; ik < k; ik++)
	{
		T frobenius = 0;
		T sum_log_diag = 0;
		for (int i = 0; i < p; i++)
		{
			T tmp = icf[icf_sz*ik + i];
			sum_log_diag = sum_log_diag + tmp;
			tmp = exp(tmp);
			frobenius = frobenius + tmp*tmp;
		}
		for (int i = p; i < icf_sz; i++)
		{
			T tmp = icf[icf_sz*ik + i];
			frobenius = frobenius + tmp*tmp;
		}
		out = out + 0.5*wishart.gamma*wishart.gamma*(frobenius)
			-wishart.m * sum_log_diag;
	}

	return out - k*C;
}

template<typename T>
void gmm_objective(int d, int k, int n, const T* const alphas, const T* const means,
	const T* const icf, const double* const x, Wishart wishart, T* err)
{
	const double CONSTANT = -n*d*0.5*log(2 * PI);
	int icf_sz = d*(d + 1) / 2;

	T *Ldiag = new T[d];
	T *xcentered = new T[d];
	T *mahal = new T[d];
	T *lse = new T[k];

	T slse = 0.;
	for (int ix = 0; ix < n; ix++)
	{
		for (int ik = 0; ik < k; ik++)
		{
			int icf_off = ik*icf_sz;
			T sumlog_Ldiag = 0.;
			for (int id = 0; id < d; id++)
			{
				sumlog_Ldiag += icf[icf_off + id];
				Ldiag[id] = exp(icf[icf_off + id]);
			}

			for (int id = 0; id < d; id++)
			{
				xcentered[id] = x[ix*d + id] - means[ik*d + id];
				mahal[id] = Ldiag[id] * xcentered[id];
			}
			int Lparamsidx = d;
			for (int i = 0; i < d; i++)
			{
				for (int j = i + 1; j < d; j++)
				{
					mahal[j] += icf[icf_off + Lparamsidx] * xcentered[i];
					Lparamsidx++;
				}
			}
			T sqsum_mahal = 0.;
			for (int id = 0; id < d; id++)
			{
				sqsum_mahal += mahal[id] * mahal[id];
			}

			lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_mahal;
		}
		slse += logsumexp(k, lse);
	}

	delete[] mahal;
	delete[] xcentered;
	delete[] Ldiag;
	delete[] lse;

	T lse_alphas = logsumexp(k, alphas);

	*err = CONSTANT + slse - n*lse_alphas;

	*err += log_wishart_prior(d, k, wishart, icf);
}

template<typename T>
void gmm_objective_split_inner(int d, int k,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const double* const x,
  Wishart wishart,
  T* err)
{
  int icf_sz = d*(d + 1) / 2;

  T *Ldiag = new T[d];
  T *xcentered = new T[d];
  T *mahal = new T[d];
  T *lse = new T[k];

  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    T sumlog_Ldiag(0.);
    for (int id = 0; id < d; id++)
    {
      sumlog_Ldiag += icf[icf_off + id];
      Ldiag[id] = exp(icf[icf_off + id]);
    }

    for (int id = 0; id < d; id++)
    {
      xcentered[id] = x[id] - means[ik*d + id];
      mahal[id] = Ldiag[id] * xcentered[id];
    }
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      for (int j = i + 1; j < d; j++)
      {
        mahal[j] += icf[icf_off + Lparamsidx] * xcentered[i];
        Lparamsidx++;
      }
    }
    T sqsum_mahal(0.);
    for (int id = 0; id < d; id++)
    {
      sqsum_mahal += mahal[id] * mahal[id];
    }

    lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_mahal;
  }

  *err = logsumexp(k, lse);

  delete[] mahal;
  delete[] xcentered;
  delete[] Ldiag;
  delete[] lse;
}

template<typename T>
void gmm_objective_split_other(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  Wishart wishart,
  T* err)
{
  const double CONSTANT = -n*d*0.5*log(2 * PI);

  T lse_alphas = logsumexp(k, alphas);

  *err = CONSTANT - n*lse_alphas + log_wishart_prior(d, k, wishart, icf);
}