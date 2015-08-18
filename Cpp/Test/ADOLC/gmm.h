#pragma once

#include <cmath>
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
#ifdef ADEPT_COMPILATION
    if (m < x[i])
      m = x[i];
#else
		m = fmax(m, x[i]);
#endif
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

template<typename T>
T sqnorm(int d,
  const T* const x)
{
  T out = 0;
  for (int i = 0; i < d; i++)
  {
    out += x[i] * x[i];
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
T log_wishart_prior(int p, int k, 
  Wishart wishart,
  const T* const sum_qs,
  const T* const Qdiags,
	const T* const icf)
{
	int n = p + wishart.m + 1;
	int icf_sz = p*(p + 1) / 2;

	double C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

	T out = 0;
	for (int ik = 0; ik < k; ik++)
	{
    T frobenius = sqnorm(p, &Qdiags[ik*p]) + sqnorm(icf_sz - p, &icf[ik*icf_sz + p]);
		out = out + 0.5*wishart.gamma*wishart.gamma*(frobenius)
			-wishart.m * sum_qs[ik];
	}

	return out - k*C;
}

template<typename T>
void preprocess_qs(int d, int k,
  const T* const icf,
  T* sum_qs,
  T* Qdiags)
{
  int icf_sz = d*(d + 1) / 2;
  for (int ik = 0; ik < k; ik++)
  {
    sum_qs[ik] = 0.;
    for (int id = 0; id < d; id++)
    {
      T q = icf[ik*icf_sz + id];
      sum_qs[ik] += q;
      Qdiags[ik*d + id] = exp(q);
    }
  }
}

template<typename T>
void Qtimesx(int d,
  const T* const Qdiag,
  const T* const ltri, // strictly lower triangular part
  const T* const x,
  T* out)
{
  for (int id = 0; id < d; id++)
    out[id] = Qdiag[id] * x[id];
  
  int Lparamsidx = 0;
  for (int i = 0; i < d; i++)
  {
    for (int j = i + 1; j < d; j++)
    {
      out[j] += ltri[Lparamsidx] * x[i];
      Lparamsidx++;
    }
  }
}

// out = a - b
template<typename T>
void subtract(int d,
  const double* const x,
  const T* const y,
  T* out)
{
  for (int id = 0; id < d; id++)
  {
    out[id] = x[id] - y[id];
  }
}

template<typename T>
void gmm_objective(int d, int k, int n, 
  const T* const alphas, 
  const T* const means,
	const T* const icf, 
  const double* const x, 
  Wishart wishart, 
  T* err)
{
	const double CONSTANT = -n*d*0.5*log(2 * PI);
	int icf_sz = d*(d + 1) / 2;

  T *sum_qs = new T[k];
  T *Qdiags = new T[d*k];
	T *xcentered = new T[d];
	T *Qxcentered = new T[d];
	T *main_term = new T[k];

  preprocess_qs(d, k, icf, sum_qs, Qdiags);

	T slse = 0.;
	for (int ix = 0; ix < n; ix++)
	{
		for (int ik = 0; ik < k; ik++)
		{
      subtract(d, &x[ix*d], &means[ik*d], xcentered);
      Qtimesx(d, &Qdiags[ik*d], &icf[ik*icf_sz + d], xcentered, Qxcentered);

      main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*sqnorm(d, Qxcentered);
		}
		slse += logsumexp(k, main_term);
	}

	delete[] xcentered;
	delete[] Qxcentered;
	delete[] main_term;

	T lse_alphas = logsumexp(k, alphas);

	*err = CONSTANT + slse - n*lse_alphas;

	*err += log_wishart_prior(d, k, wishart, sum_qs, Qdiags, icf);

  delete[] sum_qs;
  delete[] Qdiags;
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