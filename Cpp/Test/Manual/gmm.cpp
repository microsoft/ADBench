#include "gmm.h"

#include <cmath>
#include <vector>

using std::vector;

double log_gamma_distrib(double a, double p)
{
  double out = 0.25 * p * (p - 1) * log(PI);
  for (int j = 1; j <= p; j++)
  {
    out += lgamma(a + 0.5*(1 - j));
  }
  return out;
}

#ifdef DO_CPP

double arr_max(int n, const double* const x, int *max_elem_idx)
{
  double m = x[0];
  *max_elem_idx = 0;
  for (int i = 1; i < n; i++)
  {
    if (m < x[i])
    {
      m = x[i];
      *max_elem_idx = i;
    }
  }
  return m;
}

double arr_max(int n, const double* const x)
{
  int idx;
  return arr_max(n, x, &idx);
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
      - wishart.m * sumlog_Ldiags[ik];
  }
  return out - k*C;
}

void preprocess_icf(int d, int k,
  const double* const icf,
  double* Qdiags,
  double* sum_qs)
{
  int icf_sz = d*(d + 1) / 2;
  for (int i = 0; i < k; i++)
  {
    sum_qs[i] = 0.;
    for (int j = 0; j < d; j++)
    {
      Qdiags[i*d + j] = exp(icf[i*icf_sz + j]);
      sum_qs[i] += icf[i*icf_sz + j];
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

void Qtimesx(int d,
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

  vector<double> Qdiags(d*k);
  vector<double> sum_qs(k);
  vector<double> main_term(k);
  vector<double> xcentered(d);
  vector<double> Qxcentered(d);

  preprocess_icf(d, k, icf, Qdiags.data(), sum_qs.data());

  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    for (int ik = 0; ik < k; ik++)
    {
      int icf_off = ik*icf_sz;
      subtract(d, &x[ix*d], &means[ik*d], xcentered.data());
      Qtimesx(d, &Qdiags[ik*d], &icf[icf_off], xcentered.data(), Qxcentered.data());
      main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*sqsum(d, Qxcentered.data());
    }
    slse += logsumexp(k, main_term.data());
  }

  double lse_alphas = logsumexp(k, alphas);

  *err = CONSTANT + slse - n*lse_alphas +
    log_wishart_prior(d, k, wishart, sum_qs.data(), Qdiags.data(), icf);
}

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
  int max_elem;
  double mx = arr_max(n, x, &max_elem);
  double semx = 0.;
  for (int i = 0; i < n; i++)
  {
    logsumexp_partial_d[i] = exp(x[i] - mx);
    semx += logsumexp_partial_d[i];
  }
  if (semx == 0.)
  {
    memset(logsumexp_partial_d, 0, n*sizeof(double));
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

  preprocess_icf(d, k, icf, Qdiags.data(), sum_qs.data());
  
  memset(J, 0, (k + d*k + icf_sz*k) * sizeof(double));

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
      Qtimesx(d, Qdiag, &icf[icf_off], xcentered.data(), Qxcentered.data());
      Qtransposetimesx(d, Qdiag, &icf[icf_off], Qxcentered.data(), &curr_means_d[ik*d]);
      compute_q_inner_term(d, Qdiag, xcentered.data(), Qxcentered.data(), &curr_q_d[ik*d]);
      compute_L_inner_term(d, xcentered.data(), Qxcentered.data(), &curr_L_d[ik*(icf_sz - d)]);
      main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*sqsum(d, Qxcentered.data());
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

// p dim
// k number of components
// wishart parameters
// icf  (p*(p+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first p params
double log_wishart_prior(int p, int k,
  Wishart wishart,
  const ArrayXd& sum_qs,
  const vector<MatrixXd>& Qs,
  const double *icf)
{
  int n = p + wishart.m + 1;
  int icf_sz = p*(p + 1) / 2;

  double C = n*p*(log(wishart.gamma) - 0.5*log(2.)) - log_gamma_distrib(0.5*n, p);

  double sum_frob = 0;
  for (int ik = 0; ik < k; ik++)
  {
    Map<const VectorXd> L(&icf[icf_sz*ik + p], icf_sz - p);
    sum_frob += L.squaredNorm() + Qs[ik].diagonal().squaredNorm();
  }

  return 0.5*wishart.gamma*wishart.gamma*sum_frob - wishart.m*sum_qs.sum() - k*C;
}

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

void gmm_objective_no_priors(int d, int k, int n,
  Map<const ArrayXd> const& alphas,
  vector<Map<const VectorXd>> const& mus,
  ArrayXd const& sum_qs,
  vector<MatrixXd> const& Qs,
  const double *x,
  Wishart wishart,
  double *err)
{
  VectorXd xcentered(d), Qxcentered(d);
  ArrayXd lse(k);
  double slse = 0.;
  for (int ix = 0; ix < n; ix++)
  {
    Map<const VectorXd> curr_x(&x[ix*d], d);
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
    lse += alphas + sum_qs;
    slse += logsumexp(lse);
  }

  double lse_alphas = logsumexp(alphas);
  double CONSTANT = -n*d*0.5*log(2 * PI);

  *err = CONSTANT + slse - n*lse_alphas;
}

void preprocess(int d, int k,
  const double *means,
  const double *icf,
  vector<Map<const VectorXd>>& mus,
  ArrayXd& sum_qs,
  vector<MatrixXd>& Qs)
{
  int icf_sz = d*(d + 1) / 2;

  sum_qs.resize(k);
  Qs.resize(k, MatrixXd::Zero(d, d));

  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    mus.emplace_back(&means[ik*d], d);
    Map<const ArrayXd> q(&icf[icf_off], d);
    sum_qs[ik] = q.sum();
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Qs[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorXd>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx += n_curr_elems;
    }
    Qs[ik].diagonal() = q.exp();
  }
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
  ArrayXd sum_qs;
  vector<MatrixXd> Qs;
  preprocess(d, k, means, icf, mus, sum_qs, Qs);

  Map<const ArrayXd> map_alphas(alphas, k);
  gmm_objective_no_priors(d, k, n, map_alphas, mus, sum_qs,
    Qs, x, wishart, err);
  *err += log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);
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
  memset(J, 0, Jsz*sizeof(double));

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
void logsumexp(const MatrixXd& X, ArrayXd& out)
{
  RowVectorXd mX = X.colwise().maxCoeff();
  RowVectorXd semX = (X.rowwise() - mX).array().exp().matrix().colwise().sum();
  out = semX.array().log() + mX.array();
}

void gmm_objective_no_priors(int d, int k, int n,
  Map<const ArrayXd> const& alphas,
  Map<const MatrixXd> const& means,
  ArrayXd const& sum_qs,
  vector<MatrixXd> const& Qs,
  Map<const MatrixXd> const& x,
  Wishart wishart,
  double *err)
{
  MatrixXd Qxcentered(d, n), main_term(k, n);
  for (int ik = 0; ik < k; ik++)
  {
    Qxcentered.noalias() = Qs[ik] * (x.colwise() - means.col(ik));
    main_term.row(ik) = -0.5*Qxcentered.colwise().squaredNorm();
  }
  main_term.colwise() += (alphas + sum_qs).matrix();
  ArrayXd slse;
  logsumexp(main_term, slse);

  double lse_alphas = logsumexp(alphas);
  double CONSTANT = -n*d*0.5*log(2 * PI);
  double tmp = slse.sum();
  *err = CONSTANT + slse.sum() - n*lse_alphas;
}

void preprocess(int d, int k,
  const double *icf,
  ArrayXd& sum_qs,
  vector<MatrixXd>& Qs)
{
  int icf_sz = d*(d + 1) / 2;
  
  sum_qs.resize(k);
  Qs.resize(k, MatrixXd::Zero(d, d));

  for (int ik = 0; ik < k; ik++)
  {
    int icf_off = ik*icf_sz;
    Map<const ArrayXd> q(&icf[icf_off], d);
    sum_qs[ik] = q.sum();
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
    {
      int n_curr_elems = d - i - 1;
      Qs[ik].col(i).bottomRows(n_curr_elems) =
        Map<const VectorXd>(&icf[icf_off + Lparamsidx], n_curr_elems);
      Lparamsidx += n_curr_elems;
    }
    Qs[ik].diagonal() = q.exp();
  }
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
  Map<const ArrayXd> map_alphas(alphas, k);
  Map<const MatrixXd> map_means(means, d, k);
  Map<const MatrixXd> map_x(x, d, n);

  ArrayXd sum_qs;
  vector<MatrixXd> Qs;
  preprocess(d, k, icf, sum_qs, Qs);

  gmm_objective_no_priors(d, k, n, map_alphas, map_means, sum_qs,
    Qs, map_x, wishart, err);
  /**err += log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);*/
}

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
  memset(J, 0, Jsz*sizeof(double));

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

