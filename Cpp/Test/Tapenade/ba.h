#ifndef TEST_TAPENADE_BA
#define TEST_TAPENADE_BA

#include "../defs.h"
//#include "defs.h"

double sqnorm(int n, double *x);
void cross(double *a, double *b, double *out);

// rot 3 rotation parameters
// pt 3 point to be rotated
// rotatedPt 3 rotated point
// this is an efficient evaluation (part of
// the Ceres implementation)
// easy to understand calculation in matlab:
//	theta = sqrt(sum(w. ^ 2));
//	n = w / theta;
//	n_x = au_cross_matrix(n);
//	R = eye(3) + n_x*sin(theta) + n_x*n_x*(1 - cos(theta));
void rodrigues_rotate_point(double *rot, double *pt, double *rotatedPt);

// rad_params 2 radial distortion parameters
// proj 2 projection to be distorted
void radial_distort(double *rad_params, double *proj);

// cam 11 cameras in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//			  [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//			  [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X 3 point
// proj 2 projection
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void project(double *cam, double *X, double *proj);

void computeReprojError(
  double *cam,
  double *X,
  double *w,
  double feat_x,
  double feat_y,
  double *err);

void computeZachWeightError(double *w, double *err);

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
void ba_objective(int n, int m, int p,
  double *cams,
  double *X,
  double *w,
  int *obs,
  double *feats,
  double *reproj_err,
  double *w_err);

#endif //TEST_TAPENADE_BA