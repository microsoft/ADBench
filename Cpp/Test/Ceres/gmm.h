// This is the same version as for ADOLC but
// constants are casted to T before using with Ts
#pragma once

#include <cmath>
#include "../defs.h"

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// d: dim
// k: number of gaussians
// n: number of points
// alphas: k logs of mixture weights (unnormalized), so
//			weights = exp(log_alphas) / sum(exp(log_alphas))
// means: d*k component means
// icf: (d*(d+1)/2)*k inverse covariance factors 
//					every icf entry stores firstly log of diagonal and then 
//          columnwise other entris
//          To generate icf in MATLAB given covariance C :
//              L = inv(chol(C, 'lower'));
//              inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
// wishart: wishart distribution parameters
// x: d*n points
// err: 1 output
template<typename T>
void gmm_objective(int d, int k, int n, const T* const alphas, const T* const means,
  const T* const icf, const double* const x, Wishart wishart, T* err);

// split of the outer loop over points
template<typename T>
void gmm_objective_split_inner(int d, int k,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const double* const x,
  Wishart wishart,
  T* err);
// other terms which are outside the loop
template<typename T>
void gmm_objective_split_other(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  Wishart wishart,
  T* err);

// p: dim
// k: number of components
// wishart parameters
// sum_qs: k sums of log diags of Qs
// Qdiags: d*k
// icf: (p*(p+1)/2)*k inverse covariance factors
template<typename T>
T log_wishart_prior(int p, int k,
  Wishart wishart,
  const T* const sum_qs,
  const T* const Qdiags,
  const T* const icf);

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
    if (m < x[i])
      m = x[i];
  }
  return m;
}

template<typename T>
T logsumexp(int n, const T* const x)
{
  T mx = arr_max(n, x);
  T semx = T(0.);
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
  T out = T(0.);
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

  T out = T(0);
  for (int ik = 0; ik < k; ik++)
  {
    T frobenius = sqnorm(p, &Qdiags[ik*p]) + sqnorm(icf_sz - p, &icf[ik*icf_sz + p]);
    out = out + T(0.5*wishart.gamma*wishart.gamma)*frobenius
      - T(wishart.m) * sum_qs[ik];
  }

  return out - T(k*C);
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
    sum_qs[ik] = T(0.);
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

  T slse = T(0.);
  for (int ix = 0; ix < n; ix++)
  {
    for (int ik = 0; ik < k; ik++)
    {
      subtract(d, &x[ix*d], &means[ik*d], xcentered);
      Qtimesx(d, &Qdiags[ik*d], &icf[ik*icf_sz + d], xcentered, Qxcentered);

      main_term[ik] = alphas[ik] + sum_qs[ik] - T(0.5)*sqnorm(d, Qxcentered);
    }
    slse += logsumexp(k, main_term);
  }

  delete[] xcentered;
  delete[] Qxcentered;
  delete[] main_term;

  T lse_alphas = logsumexp(k, alphas);

  *err = T(CONSTANT) + slse - T(n)*lse_alphas;

  *err += log_wishart_prior(d, k, wishart, sum_qs, Qdiags, icf);

  delete[] sum_qs;
  delete[] Qdiags;
}