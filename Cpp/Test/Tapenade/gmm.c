#include "gmm.h"

#include <stdlib.h>
#include <math.h>

double arr_max(int n, double* x)
{
  double m;
  int i;

  m = x[0];
  for (i = 1; i < n; i++)
  {
    if (x[i] > m)
      m = x[i];
  }
  return m;
}

double logsumexp(int n, double* x)
{
  int i;
  double mx, semx;

  mx = arr_max(n, x);
  semx = 0.;
  for (i = 0; i < n; i++)
  {
    semx += exp(x[i] - mx);
  }
  return log(semx) + mx;
}

double log_gamma_distrib(double a, double p)
{
  int j;
  double out;

  out = 0.25 * p * (p - 1) * log(PI);
  for (j = 1; j <= p; j++)
  {
    out = out + lgamma(a + 0.5*(1 - j));
  }
  return out;
}

double log_wishart_prior(int p, int k, Wishart wishart,
  double* icf)
{
  int n, ik, i, icf_sz;
  double out, C, frobenius, sum_log_diag, tmp;

  n = p + wishart.m + 1;
  icf_sz = p*(p + 1) / 2;

  C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

  out = 0;
  for (ik = 0; ik < k; ik++)
  {
    frobenius = 0;
    sum_log_diag = 0;
    for (i = 0; i < p; i++)
    {
      tmp = icf[icf_sz*ik + i];
      sum_log_diag = sum_log_diag + tmp;
      tmp = exp(tmp);
      frobenius = frobenius + tmp*tmp;
    }
    for (i = p; i < icf_sz; i++)
    {
      tmp = icf[icf_sz*ik + i];
      frobenius = frobenius + tmp*tmp;
    }
    out = out + 0.5*wishart.gamma*wishart.gamma*(frobenius)
      -wishart.m * sum_log_diag;
  }

  return out - k*C;
}

void gmm_objective(int d, int k, int n,
  double* alphas, double* means,
  double* icf, double *x,
  Wishart wishart, double *err)
{
  int ik, ix, id, i, j, icf_sz, icf_off, Lparamsidx;
  double *lse, *Ldiag, *xcentered, *mahal;
  double sumlog_Ldiag, sqsum_mahal, slse, lse_alphas, CONSTANT;
  CONSTANT = -n*d*0.5*log(2 * PI);
  icf_sz = d*(d + 1) / 2;
  lse = (double *)malloc(k*sizeof(double));
  Ldiag = (double *)malloc(d*sizeof(double));
  xcentered = (double *)malloc(d*sizeof(double));
  mahal = (double *)malloc(d*sizeof(double));

  slse = 0.;
  for (ix = 0; ix < n; ix++)
  {
    for (ik = 0; ik < k; ik++)
    {
      icf_off = ik*icf_sz;
      sumlog_Ldiag = 0.;
      for (id = 0; id < d; id++)
      {
        sumlog_Ldiag = sumlog_Ldiag +
          icf[icf_off + id];
        Ldiag[id] = exp(icf[icf_off + id]);
      }
      for (id = 0; id < d; id++)
      {
        xcentered[id] = x[ix*d + id] - means[ik*d + id];
        mahal[id] = Ldiag[id] * xcentered[id];
      }
      Lparamsidx = d;
      for (i = 0; i < d; i++)
      {
        for (j = i + 1; j < d; j++)
        {
          mahal[j] = mahal[j] + icf[icf_off +
            Lparamsidx] * xcentered[i];
          Lparamsidx = Lparamsidx + 1;
        }
      }
      sqsum_mahal = 0.;
      for (id = 0; id < d; id++)
      {
        sqsum_mahal = sqsum_mahal + mahal[id] * mahal[id];
      }
      lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_mahal;
    }
    slse = slse + logsumexp(k, lse);
  }
  free(mahal);
  free(xcentered);
  free(Ldiag);
  free(lse);
  lse_alphas = logsumexp(k, alphas);
  *err = CONSTANT + slse - n*lse_alphas;

  *err = *err + log_wishart_prior(d, k, wishart, icf);

  // this is here so that tapenade would recognize that means and inv_cov_factors are variables
  *err = *err + ((means[0] - means[0]) +
    (icf[0] - icf[0]));
}