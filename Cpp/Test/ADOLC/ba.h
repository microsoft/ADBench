#include <stdlib.h>
#include <math.h>
#include <float.h>

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

template<typename T>
void computeReprojError(
  const T* const cam,
  const T* const X,
  const T* const w,
  const double* const feat,
  T *err);

template<typename T>
void computeZachWeightError(const T* const w, T* err);

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
template<typename T>
void ba_objective(int n, int m, int p,
  const T* const cams,
  const T* const X,
  const T* const w,
  const int* const obs,
  const double* feats,
  T* reproj_err,
  T* w_err);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

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
template<typename T>
void rodrigues_rotate_point(
  const T* const rot, 
  const T* const pt,
  T *rotatedPt)
{
  T theta, costheta, sintheta, theta_inverse,
    w[3], w_cross_pt[3], tmp;

  // norm of rot
  theta = 0.;
  for (int i = 0; i < 3; i++)
  {
    theta = theta + rot[i] * rot[i];
  }
  theta = sqrt(theta);

  costheta = cos(theta);
  sintheta = sin(theta);
  theta_inverse = 1.0 / theta;

  w[0] = rot[0] * theta_inverse;
  w[1] = rot[1] * theta_inverse;
  w[2] = rot[2] * theta_inverse;

  w_cross_pt[0] = w[1] * pt[2] - w[2] * pt[1];
  w_cross_pt[1] = w[2] * pt[0] - w[0] * pt[2];
  w_cross_pt[2] = w[0] * pt[1] - w[1] * pt[0];

  tmp = (w[0] * pt[0] + w[1] * pt[1] + w[2] * pt[2]) *
    (1. - costheta);

  rotatedPt[0] = pt[0] * costheta + w_cross_pt[0] * sintheta + w[0] * tmp;
  rotatedPt[1] = pt[1] * costheta + w_cross_pt[1] * sintheta + w[1] * tmp;
  rotatedPt[2] = pt[2] * costheta + w_cross_pt[2] * sintheta + w[2] * tmp;
}

// rad_params 2 radial distortion parameters
// proj 2 projection to be distorted
template<typename T>
void radial_distort(
  const T* const rad_params, 
  T *proj)
{
  T rsq, L;
  rsq = proj[0] * proj[0] + proj[1] * proj[1];
  L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
  proj[0] = proj[0] * L;
  proj[1] = proj[1] * L;
}

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
template<typename T>
void project(const T* const cam, 
  const T* const X, 
  T* proj)
{
  const T* const C = &cam[3];
  T Xo[3], Xcam[3];

  Xo[0] = X[0] - C[0];
  Xo[1] = X[1] - C[1];
  Xo[2] = X[2] - C[2];

  rodrigues_rotate_point(&cam[0], Xo, Xcam);

  proj[0] = Xcam[0] / Xcam[2];
  proj[1] = Xcam[1] / Xcam[2];

  radial_distort(&cam[9], proj);

  proj[0] = proj[0] * cam[6] + cam[7];
  proj[1] = proj[1] * cam[6] + cam[8];
}

template<typename T>
void computeReprojError(
  const T* const cam,
  const T* const X, 
  const T* const w, 
  const double* const feat,
  T *err)
{
  T proj[2];
  project(cam, X, proj);

  err[0] = (*w)*(proj[0] - feat[0]);
  err[1] = (*w)*(proj[1] - feat[1]);
}

template<typename T>
void computeZachWeightError(const T* const w, T* err)
{
  *err = 1 - (*w)*(*w);
}

template<typename T>
void ba_objective(int n, int m, int p,
  const T* const cams,
  const T* const X,
  const T* const w,
  const int* const obs,
  const double* feats,
  T* reproj_err,
  T* w_err)
{
  for (int i = 0; i < p; i++)
  {
    int camIdx = obs[i * 2 + 0];
    int ptIdx = obs[i * 2 + 1];
    computeReprojError(&cams[camIdx * BA_NCAMPARAMS], &X[ptIdx * 3],
      &w[i], &feats[i * 2], &reproj_err[2 * i]);
  }

  for (int i = 0; i < p; i++)
  {
    computeZachWeightError(&w[i], &w_err[i]);
  }
}