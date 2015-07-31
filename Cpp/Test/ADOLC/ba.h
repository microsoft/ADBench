#include "adolc\adolc.h"

#define BA_NCAMPARAMS 11
#define BA_ROT_IDX 0
#define BA_C_IDX 3
#define BA_F_IDX 6
#define BA_X0_IDX 7
#define BA_RAD_IDX 9

// n number of cameras
// m number of points
// p number of observations
// cams 11*n cameras in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//			  [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//			  [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X 3*m points
// obs 2*p observations (pairs cameraIdx, pointIdx)
// feats 2*p features (x,y coordinates corresponding to observations)
// reproj_err 2*p errors of observations
// f_prior_err n-2 temporal prior on focals
// w_err p coputes like 1-w^2
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void ba_objective(int n, int m, int p, const double *cams,
	const double *X, const double *w, const int *obs,
	const double *feats, double *reproj_err,
	double *f_prior_err, double *w_err);
void ba_objective(int n, int m, int p, const adouble *cams,
	const adouble *X, const adouble *w, const int *obs,
	const double *feats, adouble *reproj_err,
	adouble *f_prior_err, adouble *w_err);