#include "gmm.h"

#include <cmath>
#include <vector>

#include "Eigen\Dense"

using Eigen::Map;
using Eigen::VectorXd;
using Eigen::RowVectorXd;
using Eigen::ArrayXd;
using Eigen::MatrixXd;
using Eigen::Lower;
using std::vector;

double logsumexp(const ArrayXd& x)
{
  double mx = x.maxCoeff();
  double semx = (x.array() - mx).exp().sum();
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
double log_wishart_prior(int p, int k, 
  Wishart wishart,
  const vector<Map<const ArrayXd>>& log_Ldiags, 
  const double *icf)
{
  int n = p + wishart.m + 1;
  int icf_sz = p*(p + 1) / 2;

  double C = n*p*(log(wishart.gamma) - 0.5*log(2.)) - log_gamma_distrib(0.5*n, p);

  double out = 0;
  for (int ik = 0; ik < k; ik++)
  {
    Map<const VectorXd> L(&icf[icf_sz*ik + p], icf_sz - p);
    double frobenius = L.squaredNorm() + log_Ldiags[ik].exp().square().sum();
    double sum_log_diag = log_Ldiags[ik].sum();
    out = out + 0.5*wishart.gamma*wishart.gamma*frobenius
      - wishart.m * sum_log_diag;
  }

  return out - k*C;
}


void gmm_objective(int d, int k, int n,
  const double* alphas,
  vector<Map<const VectorXd>> const& mus,
  vector<Map<const ArrayXd>> const& qs,
  vector<MatrixXd> const& Ls,
  const double *icf,
  const double *x,
  Wishart wishart,
  double *err)
{
  int icf_sz = d*(d + 1) / 2;
  VectorXd xcentered(d), mahal(d), Ldiag(d), lse(k);
  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    Map<const VectorXd> curr_x(&x[ix], d);
    for (int ik = 0; ik < k; ik++)
    {
      int icf_off = ik*icf_sz;

      Ldiag = qs[ik].exp();

      xcentered = curr_x - mus[ik];
      mahal.noalias() = Ldiag.cwiseProduct(xcentered) +
        Ls[ik].triangularView<Eigen::StrictlyLower>()*xcentered;

      lse(ik) = alphas[ik] + qs[ik].sum() - 0.5*mahal.squaredNorm();;
    }
    slse += logsumexp(lse);
  }

  Map<const VectorXd> map_alphas(alphas, k);
  double lse_alphas = logsumexp(map_alphas);

  double CONSTANT = -n*d*0.5*log(2 * PI);

  *err = CONSTANT + slse - n*lse_alphas;

  *err += log_wishart_prior(d, k, wishart, qs, icf);
}

void gmm_objective(int d, int k, int n, 
  const double *alphas,
  const double *means, 
  const double *icf, 
  const double *x,
  Wishart wishart, 
  double *err)
{
  int icf_sz = d*(d + 1) / 2;

  // init eigen wrappers first
  vector<Map<const VectorXd>> mus;
  vector<Map<const ArrayXd>> log_Ldiags;
  vector<MatrixXd> Ls(k, MatrixXd::Zero(d, d));
  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    mus.emplace_back(&means[ik*d], d);
    log_Ldiags.emplace_back(&icf[icf_off], d);
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Ls[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorXd>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx += n_curr_elems;
    }
  }

  gmm_objective(d, k, n, alphas, mus, log_Ldiags,
    Ls, icf, x, wishart, err);
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
  const double CONSTANT = -n*d*0.5*log(2 * PI);
  int icf_sz = d*(d + 1) / 2;

  // init eigen wrappers first
  Map<RowVectorXd> alphas_d(J, k);
  Map<MatrixXd> means_d(&J[k], d, k);
  Map<MatrixXd> icf_d(&J[k + d*k], icf_sz, k);
  alphas_d.setZero(); means_d.setZero(); icf_d.setZero();
  vector<Map<const VectorXd>> mus;
  vector<Map<const ArrayXd>> log_Ldiags;
  vector<MatrixXd> Ls;
  Ls.resize(k, MatrixXd::Zero(d, d));
  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    mus.emplace_back(&means[ik*d], d);
    log_Ldiags.emplace_back(&icf[icf_off], d);
    Ls[ik].diagonal() = log_Ldiags[ik].exp();
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Ls[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorXd>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx += n_curr_elems;
    }
  }

  VectorXd xcentered(d), Lxcentered(d);
  ArrayXd main_term(k);
  MatrixXd curr_means_d(d, k);
  MatrixXd curr_logLdiag_d(d, k);
  MatrixXd curr_L_d(icf_sz - d, k);
  RowVectorXd e_main_term;
  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    Map<const VectorXd> curr_x(&x[ix], d);
    for (int ik = 0; ik < k; ik++)
    {
      int icf_off = ik*icf_sz;

      xcentered = curr_x - mus[ik];
      Lxcentered.noalias() =
        Ls[ik].triangularView<Lower>()*xcentered;
      curr_means_d.col(ik).noalias() =
        Ls[ik].triangularView<Lower>().transpose()*Lxcentered;
      curr_logLdiag_d.col(ik).noalias() =
        (1. -
          ((Ls[ik].diagonal().cwiseProduct(xcentered)).asDiagonal() *
            Lxcentered).array()).matrix();

      int Lparamsidx = 0;
      for (int i = 0; i < d; i++)
      {
        int n_curr_elems = d - i - 1;
        curr_L_d.block(Lparamsidx, ik, n_curr_elems, 1) =
          -xcentered(i)*Lxcentered.bottomRows(n_curr_elems);
        Lparamsidx += n_curr_elems;
      }

      main_term(ik) = alphas[ik] + log_Ldiags[ik].sum() - 0.5*Lxcentered.squaredNorm();
    }
    slse += logsumexp(main_term);
    e_main_term = main_term.exp();
    double normalizer = e_main_term.sum();
    if (normalizer == 0.)
      e_main_term.setZero();
    else
      e_main_term /= e_main_term.sum();
    alphas_d += e_main_term;
    for (int id = 0; id < d; id++)
    {
      means_d.row(id) += curr_means_d.row(id).cwiseProduct(e_main_term);
      icf_d.row(id) += curr_logLdiag_d.row(id).cwiseProduct(e_main_term);
    }
    for (int i = d; i < icf_sz; i++)
    {
      icf_d.row(i) += curr_L_d.row(i - d).cwiseProduct(e_main_term);
    }
  }

  for (int ik = 0; ik < k; ik++)
  {
    icf_d.block(0, ik, d, 1) += ((wishart.gamma*wishart.gamma*
      Ls[ik].diagonal().cwiseProduct(Ls[ik].diagonal()))
      .array() - wishart.m).matrix();

    icf_d.block(d, ik, icf_sz - d, 1) +=
      wishart.gamma*wishart.gamma*
      Map<const VectorXd>(&icf[ik*icf_sz + d], icf_sz - d);
  }
  
  Map<const ArrayXd> map_alphas(alphas, k);
  double lse_alphas = logsumexp(map_alphas);
  RowVectorXd e_alphas = map_alphas.exp();
  alphas_d -= (n*e_alphas) / e_alphas.sum();

  *err = CONSTANT + slse - n*lse_alphas;

  *err += log_wishart_prior(d, k, wishart, log_Ldiags, icf);
}


