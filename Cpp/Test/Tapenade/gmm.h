
#ifndef TEST_TAPENADE_GMM
#define TEST_TAPENADE_GMM

#include "../defs.h"

// This throws error on n<1
double arr_max(int n, double* x);

double logsumexp(int n, double* x);

// p dim
// k number of components
// wishart parameters
// icf  (p*(p+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first p params
double log_wishart_prior(int p, int k, Wishart wishart,
  double* icf);
double log_gamma_distrib(double a, double p);

// d dim
// k number of gaussians
// n number of points
// alphas k logs of mixture weights (unnormalized), so
//			weights = exp(log_alphas) / sum(exp(log_alphas))
// means d*k component means
// icf (d*(d+1)/2)*k parametrizing lower triangular 
//					square roots of inverse covariances log of diagonal 
//					is first d params
// wishart wishart distribution parameters
// x d*n points
// err 1 output
// To generate params in MATLAB given covariance C :
//           L = inv(chol(C, 'lower'));
//           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
void gmm_objective(int d, int k, int n,
  double* alphas, double* means,
  double* icf, double *x,
  Wishart wishart, double *err);

#endif // TEST_TAPENADE_GMM