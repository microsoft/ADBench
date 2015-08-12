#include "gmm.h"

#include <cmath>
#include <vector>

using std::vector;

#ifndef COMPILE_EIGEN_VERSION

double arr_max(int n, const double* const x)
{
  double m = x[0];
  for (int i = 1; i < n; i++)
  {
    m = fmax(m, x[i]);
  }
  return m;
}

double logsumexp(int n, const double* const x)
{
  double mx = arr_max(n, x);
  double semx = 0.;
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

double sqsum(int n, const double* const x)
{
  double sqsum_mahal = 0.;
  for (int i = 0; i < n; i++)
  {
    sqsum_mahal += x[i] * x[i];
  }
  return sqsum_mahal;
}

// p dim
// k number of components
// wishart parameters
// icf  (p*(p+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first p params
double log_wishart_prior(int p, int k, 
  Wishart wishart,
  const double* const sumlog_Ldiags,
  const double* const Ldiags,
  const double* const icf)
{
  int n = p + wishart.m + 1;
  int icf_sz = p*(p + 1) / 2;

  double C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

  double out = 0;
  for (int ik = 0; ik < k; ik++)
  {
    double frobenius = sqsum(p, &Ldiags[ik*p]) + sqsum(icf_sz - p, &icf[icf_sz*ik + p]);
    out = out + 0.5*wishart.gamma*wishart.gamma*frobenius
      -wishart.m * sumlog_Ldiags[ik];
  }
  return out - k*C;
}

void preprocess_icf(int d, int k,
  const double* const icf, 
  double *Ldiags,
  double *sumlog_Ldiags)
{
  int icf_sz = d*(d + 1) / 2;
  for (int i = 0; i < k; i++)
  {
    sumlog_Ldiags[i] = 0.;
    for (int j = 0; j < d; j++)
    {
      Ldiags[i*d + j] = exp(icf[i*icf_sz + j]);
      sumlog_Ldiags[i] += icf[i*icf_sz + j];
    }
  }
}

void subtract(int n,
  const double* const x,
  const double* const mean,
  double* xcentered)
{
  for (int id = 0; id < n; id++)
  {
    xcentered[id] = x[id] - mean[id];
  }
}

void Ltimesx(int d,
  const double* const Ldiag,
  const double* const icf,
  const double* const x,
  double* Lx)
{
  int Lparamsidx = d;
  for (int i = 0; i < d; i++)
    Lx[i] = Ldiag[i] * x[i];

  for (int i = 0; i < d; i++)
    for (int j = i + 1; j < d; j++)
    {
      Lx[j] += icf[Lparamsidx] * x[i];
      Lparamsidx++;
    }
}

void gmm_objective(int d, int k, int n, 
  const double* const alphas, 
  const double* const means,
  const double* const icf, 
  const double* const x, 
  Wishart wishart, 
  double* err)
{
  const double CONSTANT = -n*d*0.5*log(2 * PI);
  int icf_sz = d*(d + 1) / 2;

  double *Ldiags = new double[d*k];
  double *sumlog_Ldiags = new double[k];
  double *lse = new double[k];
  double *xcentered = new double[d];
  double *Lxcentered = new double[d];

  preprocess_icf(d, k, icf, Ldiags, sumlog_Ldiags);

  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    for (int ik = 0; ik < k; ik++)
    {
      int icf_off = ik*icf_sz;
      subtract(d, &x[ix*d], &means[ik*d], xcentered);
      Ltimesx(d, &Ldiags[ik*d], &icf[icf_off], xcentered, Lxcentered);
      lse[ik] = alphas[ik] + sumlog_Ldiags[ik] - 0.5*sqsum(d, Lxcentered);
    }
    slse += logsumexp(k, lse);
  }
  delete[] lse;

  double lse_alphas = logsumexp(k, alphas);

  *err = CONSTANT + slse - n*lse_alphas + 
    log_wishart_prior(d, k, wishart, sumlog_Ldiags, Ldiags, icf);

  delete[] Ldiags;
  delete[] sumlog_Ldiags;
  delete[] xcentered;
  delete[] Lxcentered;
}

void Ltransposetimesx(int d,
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

void compute_logLdiag_inner_term(int d,
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

void get_normalized_exp_term(int n,
  const double* const main_term,
  double* main_term_out)
{
  double normalizer = 0.;
  for (int i = 0; i < n; i++)
  {
    main_term_out[i] = exp(main_term[i]);
    normalizer += main_term_out[i];
  }
  if (normalizer == 0.)
    for (int i = 0; i < n; i++)
      main_term_out[i] = 0.;
  else
    for (int i = 0; i < n; i++)
      main_term_out[i] = main_term_out[i] / normalizer;
}

void get_normalized_exp_term(int n,
  double* main_term)
{
  get_normalized_exp_term(n, main_term, main_term);
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

  double *Ldiags = new double[d*k];
  double *sumlog_Ldiags = new double[k];
  double *xcentered = new double[d];
  double *Lxcentered = new double[d];

  preprocess_icf(d, k, icf, Ldiags, sumlog_Ldiags);

  memset(J, 0, (k + d*k +icf_sz*k) * sizeof(double));

  double *main_term = new double[k];
  double *curr_means_d = new double[d*k];
  double *curr_logLdiag_d = new double[d*k];
  double *curr_L_d = new double[(icf_sz - d) * k];

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
      subtract(d, curr_x, &means[ik*d], xcentered);
      Ltimesx(d, &Ldiags[ik*d], &icf[icf_off], xcentered, Lxcentered);
      Ltransposetimesx(d, &Ldiags[ik*d], &icf[icf_off], Lxcentered, &curr_means_d[ik*d]);
      compute_logLdiag_inner_term(d, &Ldiags[ik*d], xcentered, Lxcentered, &curr_logLdiag_d[ik*d]);
      compute_L_inner_term(d, xcentered, Lxcentered, &curr_L_d[ik*(icf_sz - d)]);
      main_term[ik] = alphas[ik] + sumlog_Ldiags[ik] - 0.5*sqsum(d, Lxcentered);
    }
    slse += logsumexp(k,main_term);
    get_normalized_exp_term(k, main_term);
    for (int ik = 0; ik < k; ik++)
    {
      int means_off = ik*d;
      int icf_off = ik*icf_sz;
      alphas_d[ik] += main_term[ik];
      for (int id = 0; id < d; id++)
      {
        means_d[means_off + id] += curr_means_d[means_off + id] * main_term[ik];
        icf_d[icf_off + id] += curr_logLdiag_d[ik*d + id] * main_term[ik];
      }
      for (int i = d; i < icf_sz; i++)
      {
        icf_d[icf_off + i] += curr_L_d[ik*(icf_sz - d) + (i - d)] * main_term[ik];
      }
    }
  }

  get_normalized_exp_term(k, alphas, main_term);
  for (int ik = 0; ik < k; ik++)
  {
    alphas_d[ik] -= n*main_term[ik];
    for (int id = 0; id < d; id++)
    {
      icf_d[ik*icf_sz + id] += wishart.gamma*wishart.gamma * Ldiags[ik*d + id] * Ldiags[ik*d + id]
        - wishart.m;
    }
    for (int i = d; i < icf_sz; i++)
    {
      icf_d[ik*icf_sz + i] += wishart.gamma*wishart.gamma*icf[ik*icf_sz + i];
    }
  }

  double lse_alphas = logsumexp(k,alphas);
  *err = CONSTANT + slse - n*lse_alphas;
  *err += log_wishart_prior(d, k, wishart, sumlog_Ldiags, Ldiags, icf);
  
  delete[] Ldiags;
  delete[] sumlog_Ldiags;
  delete[] xcentered;
  delete[] Lxcentered;
  delete[] main_term;
  delete[] curr_means_d;
  delete[] curr_logLdiag_d;
  delete[] curr_L_d;
}

#else

#include "Eigen\Dense"

using Eigen::Map;
using Eigen::VectorXd;
using Eigen::RowVectorXd;
using Eigen::ArrayXd;
using Eigen::MatrixXd;
using Eigen::Lower;

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

#endif

