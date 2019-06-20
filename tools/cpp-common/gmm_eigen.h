#include <cmath>
#include <vector>
#include "defs.h"
#include "matrix.h"

#include "Eigen/Dense"

using std::vector;

using Eigen::Map;
template<typename T>
using VectorX = Eigen::Matrix<T, -1, 1>;
template<typename T>
using RowVectorX = Eigen::Matrix<T, 1, -1>;
template<typename T>
using MatrixX = Eigen::Matrix<T, -1, -1>;
template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

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
void gmm_objective(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const T* const x,
  Wishart wishart,
  T* err);

template<typename T>
double logsumexp(const ArrayX<T>& x);

// p: dim
// k: number of components
// wishart parameters
// sum_qs: sum of log diags of Qs
// Qs: icf composed into matrices
// icf: (p*(p+1)/2)*k inverse covariance factors
template<typename T>
double log_wishart_prior(int p, int k,
  Wishart wishart,
  const ArrayX<T>& sum_qs,
  const vector<MatrixX<T>>& Qs,
  const T* const icf);

#ifdef DO_EIGEN

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
  const Map<const ArrayX<T>>& alphas,
  const vector<Map<const VectorX<T>>>& mus,
  const ArrayX<T>& sum_qs,
  const vector<MatrixX<T>>& Qs,
  const double* const x,
  Wishart wishart,
  T* err);

template<typename T>
void preprocess(int d, int k,
  const T* const means,
  const T* const icf,
  vector<Map<const VectorX<T>>>& mus,
  ArrayX<T>& sum_qs,
  vector<MatrixX<T>>& Qs);

#elif defined DO_EIGEN_VECTOR

// logsumexp of cols
template<typename T>
void logsumexp(const MatrixX<T>& X, ArrayX<T>& out);

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
  Map<const ArrayX<T>> const& alphas,
  Map<const MatrixX<T>> const& means,
  ArrayX<T> const& sum_qs,
  vector<MatrixX<T>> const& Qs,
  Map<const MatrixX<T>> const& x,
  Wishart wishart,
  T* err);

template<typename T>
void preprocess(int d, int k,
  const T* const icf,
  ArrayX<T>& sum_qs,
  vector<MatrixX<T>>& Qs);


#endif

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////


template<typename T>
T logsumexp(const ArrayX<T>& x)
{
  T mx = x.maxCoeff();
  T semx = (x.array() - mx).exp().sum();
  return log(semx) + mx;
}

template<typename T>
double log_wishart_prior(int p, int k,
  Wishart wishart,
  const ArrayX<T>& sum_qs,
  const vector<MatrixX<T>>& Qs,
  const T* const icf)
{
  int n = p + wishart.m + 1;
  int icf_sz = p*(p + 1) / 2;

  double C = n*p*(log(wishart.gamma) - 0.5*log(2.)) - log_gamma_distrib(0.5*n, p);

  double sum_frob = 0;
  for (int ik = 0; ik < k; ik++)
  {
    Map<const VectorX<T>> L(&icf[icf_sz*ik + p], icf_sz - p);
    sum_frob = sum_frob + L.squaredNorm() + Qs[ik].diagonal().squaredNorm();
  }

  return 0.5*wishart.gamma*wishart.gamma*sum_frob - wishart.m*sum_qs.sum() - k*C;
}

#ifdef DO_EIGEN

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
  const Map<const ArrayX<T>>& alphas,
  const vector<Map<const VectorX<T>>>& mus,
  const ArrayX<T>& sum_qs,
  const vector<MatrixX<T>>& Qs,
  const double* const x,
  Wishart wishart,
  T* err)
{
  VectorX<T> xcentered(d), Qxcentered(d);
  ArrayX<T> lse(k);
  T slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    Map<const VectorX<T>> curr_x(&x[ix*d], d);
    for (int ik = 0; ik < k; ik++)
    {
      switch (3) // 3 is the fastest, (and 2 is slightly faster than 4)
      {
      case 2:
        xcentered = curr_x - mus[ik];
        Qxcentered.noalias() = Qs[ik].triangularView<Eigen::Lower>()*xcentered;
        lse(ik) = -0.5*Qxcentered.squaredNorm();
        break;
      case 3:
        xcentered = curr_x - mus[ik];
        Qxcentered.noalias() = Qs[ik] * xcentered;
        lse(ik) = -0.5*Qxcentered.squaredNorm();
        break;
      case 4:
        lse(ik) = -0.5*(Qs[ik].triangularView<Eigen::Lower>() * (curr_x - mus[ik])).squaredNorm();
        break;
      }
    }
    lse = lse + alphas + sum_qs;
    slse = slse + logsumexp(lse);
  }

  T lse_alphas = logsumexp(alphas);
  double CONSTANT = -n*d*0.5*log(2 * PI);

  *err = CONSTANT + slse - n*lse_alphas;
}

template<typename T>
void preprocess(int d, int k,
  const T* const means,
  const T* const icf,
  vector<Map<const VectorX<T>>>& mus,
  ArrayX<T>& sum_qs,
  vector<MatrixX<T>>& Qs)
{
  int icf_sz = d*(d + 1) / 2;

  sum_qs.resize(k);
  Qs.resize(k, MatrixX<T>::Zero(d, d));

  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    mus.emplace_back(&means[ik*d], d);
    Map<const ArrayX<T>> q(&icf[icf_off], d);
    sum_qs[ik] = q.sum();
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Qs[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorX<T>>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx = Lparamsidx + n_curr_elems;
    }
    Qs[ik].diagonal() = q.exp();
  }
}

template<typename T>
void gmm_objective(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const T* const x,
  Wishart wishart,
  T* err)
{
  int icf_sz = d*(d + 1) / 2;

  // init eigen wrappers first
  vector<Map<const VectorX<T>>> mus;
  ArrayX<T> sum_qs;
  vector<MatrixX<T>> Qs;
  preprocess(d, k, means, icf, mus, sum_qs, Qs);

  Map<const ArrayX<T>> map_alphas(alphas, k);
  gmm_objective_no_priors(d, k, n, map_alphas, mus, sum_qs,
    Qs, x, wishart, err);
  *err = *err + log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);
}

#elif defined DO_EIGEN_VECTOR

// logsumexp of cols
template<typename T>
void logsumexp(const MatrixX<T>& X, ArrayX<T>& out)
{
  RowVectorX<T> mX = X.colwise().maxCoeff();
  RowVectorX<T> semX = (X.rowwise() - mX).array().exp().matrix().colwise().sum();
  out = semX.array().log() + mX.array();
}

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
  Map<const ArrayX<T>> const& alphas,
  Map<const MatrixX<T>> const& means,
  ArrayX<T> const& sum_qs,
  vector<MatrixX<T>> const& Qs,
  Map<const MatrixX<T>> const& x,
  Wishart wishart,
  T* err)
{
  MatrixX<T> Qxcentered(d, n), main_term(k, n);
  for (int ik = 0; ik < k; ik++)
  {
    Qxcentered.noalias() = Qs[ik] * (x.colwise() - means.col(ik));
    main_term.row(ik) = -0.5*Qxcentered.colwise().squaredNorm();
  }
  main_term.colwise() += (alphas + sum_qs).matrix();
  ArrayX<T> slse;
  logsumexp(main_term, slse);

  T lse_alphas = logsumexp(alphas);
  double CONSTANT = -n*d*0.5*log(2 * PI);
  T tmp = slse.sum();
  *err = CONSTANT + slse.sum() - n*lse_alphas;
}

template<typename T>
void preprocess(int d, int k,
  const T* const icf,
  ArrayX<T>& sum_qs,
  vector<MatrixX<T>>& Qs)
{
  int icf_sz = d*(d + 1) / 2;

  sum_qs.resize(k);
  Qs.resize(k, MatrixX<T>::Zero(d, d));

  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    Map<const ArrayX<T>> q(&icf[icf_off], d);
    sum_qs[ik] = q.sum();
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Qs[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorX<T>>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx += n_curr_elems;
    }
    Qs[ik].diagonal() = q.exp();
  }
}

template<typename T>
void gmm_objective(int d, int k, int n,
  const T* const alphas,
  const T* const means,
  const T* const icf,
  const T* const x,
  Wishart wishart,
  T* err)
{
  int icf_sz = d*(d + 1) / 2;

  // init eigen wrappers first
  Map<const ArrayX<T>> map_alphas(alphas, k);
  Map<const MatrixX<T>> map_means(means, d, k);
  Map<const MatrixX<T>> map_x(x, d, n);

  ArrayX<T> sum_qs;
  vector<MatrixX<T>> Qs;
  preprocess(d, k, icf, sum_qs, Qs);

  gmm_objective_no_priors(d, k, n, map_alphas, map_means, sum_qs,
    Qs, map_x, wishart, err);
  *err += log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);
}

#endif
