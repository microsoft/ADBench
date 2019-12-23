// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <stdlib.h>
#include <math.h>
#include <float.h>

#include "Eigen/Dense"

#ifdef TOOL_ADOLC
#include "adolc/adouble.h"
#endif

using Eigen::Map;
template<typename T>
using VectorX = Eigen::Matrix<T, -1, 1>;
template<typename T>
using Vector3 = Eigen::Matrix<T, 3, 1>;
template<typename T>
using Vector2 = Eigen::Matrix<T, 2, 1>;

#include "defs.h"

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// cam: 11 camera in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//			  [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//			  [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X: 3 point
// feats: 2 feature (x,y coordinates)
// reproj_err: 2
// projection function: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
template<typename T>
void computeReprojError(
  const T* const cam,
  const T* const X,
  const T* const w,
  const double* const feat,
  T *err);

// w: 1
// w_err: 1
template<typename T>
void computeZachWeightError(const T* const w, T* err);

// n number of cameras
// m number of points
// p number of observations
// cams: 11*n cameras in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//			  [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//			  [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X: 3*m points
// obs: 2*p observations (pairs cameraIdx, pointIdx)
// feats: 2*p features (x,y coordinates corresponding to observations)
// reproj_err: 2*p errors of observations
// w_err: p weight "error" terms
// projection function: 
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
  const double* const feats,
  T* reproj_err,
  T* w_err);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

// ADOLC did not work with simply calling Eigen cross
template<typename T>
void cross(
  const T* const a_,
  const Vector3<T>& b,
  Vector3<T>& out)
{
  Map<const Vector3<T>> a(a_);
  out[0] = a[1] * b[2] - a[2] * b[1];
  out[1] = a[2] * b[0] - a[0] * b[2];
  out[2] = a[0] * b[1] - a[1] * b[0];
}

template<typename T>
void rodrigues_rotate_point(
  Map<const Vector3<T>>& rot,
  const Vector3<T>& X,
  Vector3<T>& rotatedX)
{
  T sqtheta = rot.squaredNorm();
  if (sqtheta != 0)
  {
    T theta = sqrt(sqtheta);
    T costheta = cos(theta);
    T sintheta = sin(theta);
    T theta_inverse = 1.0 / theta;

    Vector3<T> w = rot*theta_inverse;

    T tmp = w.dot(X) * (1. - costheta);

    rotatedX = X*costheta + w.cross(X)*sintheta + w*tmp;
  }
  else
  {
    rotatedX = X + rot.cross(X);
  }
}
#ifdef TOOL_ADOLC
template<>
void rodrigues_rotate_point(
  Map<const Vector3<adouble>>& rot,
  const Vector3<adouble>& X,
  Vector3<adouble>& rotatedX)
{
  adouble sqtheta = rot.squaredNorm();
  if (sqtheta != 0)
  {
    adouble theta = sqrt(sqtheta);
    adouble costheta = cos(theta);
    adouble sintheta = sin(theta);
    adouble theta_inverse = 1.0 / theta;

    Vector3<adouble> w = rot*theta_inverse;
    
    Vector3<adouble> w_cross_X;
    cross(w.data(), X, w_cross_X);

    adouble tmp = w.dot(X) * (1. - costheta);

    rotatedX = X*costheta + w_cross_X*sintheta + w*tmp;
  }
  else
  {
    Vector3<adouble> rot_cross_X;
    cross(rot.data(), X, rot_cross_X);
    rotatedX = X + rot_cross_X;
  }
}
#endif

template<typename T>
void radial_distort(
  const T* const rad_params,
  Vector2<T>& proj)
{
  T rsq = proj.squaredNorm();
  T L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
  proj *= L;
}

template<typename T>
void project(const T* const cam, Map<const Vector3<T>>& X, Vector2<T>& proj)
{
  Map<const Vector3<T>> rot(&cam[BA_ROT_IDX]);
  Map<const Vector3<T>> C(&cam[BA_C_IDX]);
  Map<const Vector2<T>> x0(&cam[BA_X0_IDX]);
  Vector3<T> Xo, Xcam;

  Xo = X - C;

  rodrigues_rotate_point(rot, Xo, Xcam);
 
  proj = Xcam.hnormalized();

  radial_distort(&cam[BA_RAD_IDX], proj);

  proj = proj * cam[BA_F_IDX] + x0;
}

template<typename T>
void computeReprojError(
  const T* const cam,
  const T* const X,
  const T* const w,
  const double* const feat,
  T *err)
{
  Map<const Vector3<T>> X_(X);
  Map<const Vector2<double>> feat_(feat);
  Map<Vector2<T>> err_(err);
  Vector2<T> proj;
  
  project(cam, X_, proj);
  err_ = (*w)*(proj - feat_.cast<T>());
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
  const double* const feats,
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