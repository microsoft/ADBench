#pragma once

#include "../../shared/defs.h"

// d: dim
// k: number of gaussians
// n: number of points
// alphas: k logs of mixture weights (unnormalized), so
//            weights = exp(log_alphas) / sum(exp(log_alphas))
// means: d*k component means
// icf: (d*(d+1)/2)*k inverse covariance factors 
//                    every icf entry stores firstly log of diagonal and then 
//          columnwise other entris
//          To generate icf in MATLAB given covariance C :
//              L = inv(chol(C, 'lower'));
//              inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
// wishart: wishart distribution parameters
// x: d*n points
// err: 1 output
void gmm_objective_d(int d, int k, int n,
  const double *alphas,
  const double *means,
  const double *icf,
  const double *x,
  Wishart wishart,
  double *err,
  double *J);
