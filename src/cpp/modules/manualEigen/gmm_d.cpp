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
