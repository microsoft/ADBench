#include "gmm_d.h"

#include <cmath>
#include <vector>

#include "../../src/cpp/shared/defs.h"
#include "../../src/cpp/shared/matrix.h"

using std::vector;

#include "../../src/cpp/shared/gmm.h"

void Qtransposetimesx(int d,
  const double* const Ldiag,
  const double* const icf,
  const double* const x,
  double* Ltransposex)
{
  int Lparamsidx = d;
  for (int i = 0; i < d; i++)
    Ltransposex[i] = Ldiag[i] * x[i];

  for (int i = 0; i < d; i++)
    for (int j = i + 1; j < d; j++)
    {
      Ltransposex[i] += icf[Lparamsidx] * x[j];
      Lparamsidx++;
    }
}

void compute_q_inner_term(int d,
  const double* const Ldiag,
  const double* const xcentered,
  const double* const Lxcentered,
  double* logLdiag_d)
{
  for (int i = 0; i < d; i++)
  {
    logLdiag_d[i] = 1. - Ldiag[i] * xcentered[i] * Lxcentered[i];
  }
}

void compute_L_inner_term(int d,
  const double* const xcentered,
  const double* const Lxcentered,
  double* L_d)
{
  int Lparamsidx = 0;
  for (int i = 0; i < d; i++)
  {
    int n_curr_elems = d - i - 1;
    for (int j = 0; j < n_curr_elems; j++)
    {
      L_d[Lparamsidx] = -xcentered[i] * Lxcentered[d - n_curr_elems + j];
      Lparamsidx++;
    }
  }
}

double logsumexp_d(int n, const double* const x, double *logsumexp_partial_d)
{
  int max_elem = arr_max_idx(n, x);
  double mx = x[max_elem];
  double semx = 0.;
  for (int i = 0; i < n; i++)
  {
    logsumexp_partial_d[i] = exp(x[i] - mx);
    semx += logsumexp_partial_d[i];
  }
  if (semx == 0.)
  {
	std::fill(logsumexp_partial_d, logsumexp_partial_d + n, 0.0);
  }
  else
  {
    logsumexp_partial_d[max_elem] -= semx;
    for (int i = 0; i < n; i++)
      logsumexp_partial_d[i] /= semx;
  }
  logsumexp_partial_d[max_elem] += 1.;
  return log(semx) + mx;
}

#ifndef DO_EIGEN

void gmm_objective_d(int d, int k, int n,
  const double *alphas,
  const double *means,
  const double *icf,
  const double *x,
  Wishart wishart,
  double *err,
  double *J)
{
  const double CONSTANT = -n*d*0.5*log(2 * PI);
  int icf_sz = d*(d + 1) / 2;

  vector<double> Qdiags(d*k);
  vector<double> sum_qs(k);
  vector<double> main_term(k);
  vector<double> xcentered(d);
  vector<double> Qxcentered(d);

  preprocess_qs(d, k, icf, sum_qs.data(), Qdiags.data());
  
  std::fill(J, J + (k + d * k + icf_sz * k), 0.0);

  vector<double> curr_means_d(d*k);
  vector<double> curr_q_d(d*k);
  vector<double> curr_L_d((icf_sz - d) * k);

  double *alphas_d = J;
  double *means_d = &J[k];
  double *icf_d = &J[k + d*k];

  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    const double* const curr_x = &x[ix*d];
    for (int ik = 0; ik < k; ik++)
    {
      int icf_off = ik*icf_sz;
      double *Qdiag = &Qdiags[ik*d];

      subtract(d, curr_x, &means[ik*d], xcentered.data());
      Qtimesx(d, Qdiag, &icf[ik*icf_sz + d], xcentered.data(), Qxcentered.data());
      Qtransposetimesx(d, Qdiag, &icf[icf_off], Qxcentered.data(), &curr_means_d[ik*d]);
      compute_q_inner_term(d, Qdiag, xcentered.data(), Qxcentered.data(), &curr_q_d[ik*d]);
      compute_L_inner_term(d, xcentered.data(), Qxcentered.data(), &curr_L_d[ik*(icf_sz - d)]);
      main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*sqnorm(d, Qxcentered.data());
    }
    slse += logsumexp_d(k, main_term.data(), main_term.data());
    for (int ik = 0; ik < k; ik++)
    {
      int means_off = ik*d;
      int icf_off = ik*icf_sz;
      alphas_d[ik] += main_term[ik];
      for (int id = 0; id < d; id++)
      {
        means_d[means_off + id] += curr_means_d[means_off + id] * main_term[ik];
        icf_d[icf_off + id] += curr_q_d[ik*d + id] * main_term[ik];
      }
      for (int i = d; i < icf_sz; i++)
      {
        icf_d[icf_off + i] += curr_L_d[ik*(icf_sz - d) + (i - d)] * main_term[ik];
      }
    }
  }

  vector<double> lse_alphas_d(k);
  double lse_alphas = logsumexp_d(k, alphas, lse_alphas_d.data());
  for (int ik = 0; ik < k; ik++)
  {
    alphas_d[ik] -= n*lse_alphas_d[ik];
    for (int id = 0; id < d; id++)
    {
      icf_d[ik*icf_sz + id] += wishart.gamma*wishart.gamma * Qdiags[ik*d + id] * Qdiags[ik*d + id]
        - wishart.m;
    }
    for (int i = d; i < icf_sz; i++)
    {
      icf_d[ik*icf_sz + i] += wishart.gamma*wishart.gamma*icf[ik*icf_sz + i];
    }
  }

  *err = CONSTANT + slse - n*lse_alphas;
  *err += log_wishart_prior(d, k, wishart, sum_qs.data(), Qdiags.data(), icf);
}

#endif

#if defined DO_EIGEN || defined DO_EIGEN_VECTOR

#include "Eigen/Dense"

#include "../cpp-common/gmm_eigen.h"

using Eigen::Map;
using Eigen::VectorXd;
using Eigen::RowVectorXd;
using Eigen::ArrayXd;
using Eigen::MatrixXd;
using Eigen::Lower;

double logsumexp_d(const ArrayXd& x, ArrayXd& logsumexp_partial_d)
{
  ArrayXd::Index maxElem;
  double mx = x.maxCoeff(&maxElem);
  logsumexp_partial_d = (x - mx).exp();
  double semx = logsumexp_partial_d.sum();
  if (semx == 0.)
  {
    logsumexp_partial_d.setZero();
  }
  else
  {
    logsumexp_partial_d(maxElem) -= semx;
    logsumexp_partial_d /= semx;
  }
  logsumexp_partial_d(maxElem) += 1.;
  return log(semx) + mx;
}

double log_wishart_prior_d(int p, int k,
  Wishart wishart,
  const ArrayXd& sum_qs,
  const vector<MatrixXd>& Qs,
  const double *icf,
  double *J)
{
  int n = p + wishart.m + 1;
  int icf_sz = p*(p + 1) / 2;
  Map<MatrixXd> icf_d(&J[k + p*k], icf_sz, k);

  for (int ik = 0; ik < k; ik++)
  {
    icf_d.block(0, ik, p, 1) +=
      (wishart.gamma*wishart.gamma*(Qs[ik].diagonal().array().square()) - wishart.m).matrix();

    icf_d.block(p, ik, icf_sz - p, 1) +=
      wishart.gamma*wishart.gamma*
      Map<const VectorXd>(&icf[ik*icf_sz + p], icf_sz - p);
  }

  return log_wishart_prior(p, k, wishart, sum_qs, Qs, icf);
}

#endif

#if defined DO_EIGEN

void gmm_objective_no_priors_d(int d, int k, int n,
  Map<const ArrayXd> const& alphas,
  vector<Map<const VectorXd>> const& mus,
  ArrayXd const& sum_qs,
  vector<MatrixXd> const& Qs,
  const double *x,
  Wishart wishart,
  double *err,
  double *J)
{
  int icf_sz = d*(d + 1) / 2;
  Map<RowVectorXd> alphas_d(J, k);
  Map<MatrixXd> means_d(&J[k], d, k);
  Map<MatrixXd> icf_d(&J[k + d*k], icf_sz, k);

  VectorXd xcentered(d), Qxcentered(d);
  ArrayXd main_term(k);
  MatrixXd curr_means_d(d, k);
  MatrixXd curr_logLdiag_d(d, k);
  MatrixXd curr_L_d(icf_sz - d, k);
  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    Map<const VectorXd> curr_x(&x[ix*d], d);
    for (int ik = 0; ik < k; ik++)
    {
      xcentered = curr_x - mus[ik];
      Qxcentered.noalias() = Qs[ik]*xcentered;
      curr_means_d.col(ik).noalias() = Qs[ik].transpose()*Qxcentered;
      curr_logLdiag_d.col(ik).noalias() =
        (1. - ((Qs[ik].diagonal().cwiseProduct(xcentered)).cwiseProduct(Qxcentered)).array()).matrix();

      int Lparamsidx = 0;
      for (int i = 0; i < d; i++)
      {
        int n_curr_elems = d - i - 1;
        curr_L_d.block(Lparamsidx, ik, n_curr_elems, 1) = -xcentered(i)*Qxcentered.bottomRows(n_curr_elems);
        Lparamsidx += n_curr_elems;
      }

      main_term(ik) = -0.5*Qxcentered.squaredNorm();
    }
    main_term += alphas + sum_qs;
    slse += logsumexp_d(main_term, main_term);
    alphas_d += main_term.matrix();
    means_d += (curr_means_d.array().rowwise() * main_term.transpose()).matrix();
    icf_d.topRows(d) += (curr_logLdiag_d.array().rowwise() * main_term.transpose()).matrix();
    icf_d.bottomRows(icf_sz - d) += (curr_L_d.array().rowwise() * main_term.transpose()).matrix();
  }

  ArrayXd logsumexp_alphas_d;
  double lse_alphas = logsumexp_d(alphas, logsumexp_alphas_d);
  alphas_d -= (n*logsumexp_alphas_d.matrix());

  const double CONSTANT = -n*d*0.5*log(2 * PI);
  *err = CONSTANT + slse - n*lse_alphas;
}

void gmm_objective_d(int d, int k, int n,
  const double *alphas,
  const double *means,
  const double *icf,
  const double *x,
  Wishart wishart,
  double *err,
  double *J)
{
  int icf_sz = d*(d + 1) / 2;
  int Jsz = k + k*d + k*icf_sz;
  std::fill(J, J + Jsz, (double)0);

  // init eigen wrappers first
  vector<Map<const VectorXd>> mus;
  ArrayXd sum_qs;
  vector<MatrixXd> Qs;
  preprocess(d, k, means, icf, mus, sum_qs, Qs);

  Map<const ArrayXd> map_alphas(alphas, k);
  gmm_objective_no_priors_d(d, k, n, map_alphas, mus, sum_qs,
    Qs, x, wishart, err, J);
  *err += log_wishart_prior_d(d, k, wishart, sum_qs, Qs, icf, J);
}

#elif DO_EIGEN_VECTOR

// logsumexp of cols
void logsumexp_d(const MatrixXd& X, ArrayXd& lse, MatrixXd& logsumexp_partial_d)
{
  vector<MatrixXd::Index> max_elem_idxs(X.cols());
  RowVectorXd mX(X.cols());
  for (int i = 0; i < X.cols(); i++)
  {
    mX(i) = X.col(i).maxCoeff(&max_elem_idxs[i]);
  }
  logsumexp_partial_d = (X.rowwise() - mX).array().exp().matrix();
  RowVectorXd semX = logsumexp_partial_d.colwise().sum();
  for (int i = 0; i < semX.cols(); i++)
  {
    if (semX(i) == 0.)
    {
      logsumexp_partial_d.col(i).setZero();
    }
    else
    {
      (logsumexp_partial_d.col(i))(max_elem_idxs[i]) -= semX(i);
      logsumexp_partial_d.col(i).array() /= semX(i);
    }
    (logsumexp_partial_d.col(i))(max_elem_idxs[i]) += 1.;
  }
  lse = semX.array().log() + mX.array();
}
  
void gmm_objective_no_priors_d(int d, int k, int n,
  Map<const ArrayXd> const& alphas,
  Map<const MatrixXd> const& means,
  ArrayXd const& sum_qs,
  vector<MatrixXd> const& Qs,
  Map<const MatrixXd> const& x,
  Wishart wishart,
  double *err,
  double *J)
{
  int icf_sz = d*(d + 1) / 2;
  Map<RowVectorXd> alphas_d(J, k);
  Map<MatrixXd> means_d(&J[k], d, k);
  Map<MatrixXd> icf_d(&J[k + d*k], icf_sz, k);

  MatrixXd xcentered(d, n);
  MatrixXd Qxcentered(d, n);
  MatrixXd main_term(k, n);
  vector<MatrixXd> tmp_means_d(k);
  vector<MatrixXd> tmp_qs_d(k);
  vector<MatrixXd> tmp_L_d(k);
  for (int ik = 0; ik < k; ik++)
  {
    xcentered = x.colwise() - means.col(ik);
    Qxcentered.noalias() = Qs[ik] * xcentered;
    main_term.row(ik) = -0.5*Qxcentered.colwise().squaredNorm();
    
    tmp_means_d[ik].noalias() = Qs[ik].transpose() * Qxcentered;
    tmp_qs_d[ik].noalias() = (1. -
      (xcentered.cwiseProduct(Qxcentered).array().colwise() * Qs[ik].diagonal().array()))
      .matrix();


    tmp_L_d[ik].resize(icf_sz - d, n);
    int Lparamsidx = 0;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      tmp_L_d[ik].middleRows(Lparamsidx, n_curr_elems).noalias() = 
        -(Qxcentered.bottomRows(n_curr_elems).array().rowwise() * xcentered.row(i).array()).matrix();
      Lparamsidx += n_curr_elems;
    }
  }
  main_term.colwise() += (alphas + sum_qs).matrix();
  ArrayXd slse;
  logsumexp_d(main_term, slse, main_term);
  
  alphas_d = main_term.rowwise().sum().transpose();
  
  for (int ik = 0; ik < k; ik++)
  {
    means_d.col(ik) = (tmp_means_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
    icf_d.col(ik).topRows(d) = (tmp_qs_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
    icf_d.col(ik).bottomRows(icf_sz - d) = (tmp_L_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
  }

  ArrayXd logsumexp_alphas_d;
  double lse_alphas = logsumexp_d(alphas, logsumexp_alphas_d);
  alphas_d -= (n*logsumexp_alphas_d.matrix());

  double CONSTANT = -n*d*0.5*log(2 * PI);
  double tmp = slse.sum();
  *err = CONSTANT + slse.sum() - n*lse_alphas;
}

void gmm_objective_d(int d, int k, int n,
  const double *alphas,
  const double *means,
  const double *icf,
  const double *x,
  Wishart wishart,
  double *err,
  double *J)
{
  int icf_sz = d*(d + 1) / 2;
  int Jsz = k + k*d + k*icf_sz;
  std::fill(J, J + Jsz, (double)0);

  // init eigen wrappers first
  Map<const ArrayXd> map_alphas(alphas, k);
  Map<const MatrixXd> map_means(means, d, k);
  Map<const MatrixXd> map_x(x, d, n);

  ArrayXd sum_qs;
  vector<MatrixXd> Qs;
  preprocess(d, k, icf, sum_qs, Qs);

  gmm_objective_no_priors_d(d, k, n, map_alphas, map_means, sum_qs,
    Qs, map_x, wishart, err, J);
  *err += log_wishart_prior_d(d, k, wishart, sum_qs, Qs, icf, J);
}

#endif

