#include "gmm_d.h"

#include <cmath>
#include <vector>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"

using std::vector;

#include "../../shared/gmm.h"

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

#include "Eigen/Dense"

#include "../../shared/gmm_eigen.h"

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
