#ifndef TEST_MANUAL_GMM
#define TEST_MANUAL_GMM

#include "../defs.h"

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
void gmm_objective(int d, int k, int n, const double *alphas,
	const double *means, const double *icf, const double *x,
	Wishart wishart, double *err);

void gmm_objective_d(int d, int k, int n, const double *alphas,
	const double *means, const double *icf, const double *x,
	Wishart wishart, double *err, double *J);


#endif // TEST_MANUAL_GMM