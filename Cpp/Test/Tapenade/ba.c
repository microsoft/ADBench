#include "ba.h"
#include <stdlib.h>
#include <math.h>
#include <float.h>

void rodrigues_rotate_point(double *rot, double *pt, double *rotatedPt)
{
  int i;
  double theta, costheta, sintheta, theta_inverse,
    w[3], w_cross_pt[3], tmp;

  // norm of rot
  theta = 0.;
  for (i = 0; i < 3; i++)
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

void radial_distort(double *rad_params, double *proj)
{
  double rsq, L;
  rsq = proj[0] * proj[0] + proj[1] * proj[1];
  L = 1 + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
  proj[0] = proj[0] * L;
  proj[1] = proj[1] * L;
}

void project(double *cam, double *X, double *proj)
{
  double *C;
  double Xo[3], Xcam[3];
  C = &cam[3];

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

void computeReprojError(double *cam,
  double *X, double *w, double feat_x, double feat_y,
  double *err)
{
  double proj[2];
  project(cam, X, proj);

  err[0] = (*w)*(proj[0] - feat_x);
  err[1] = (*w)*(proj[1] - feat_y);
}

// temporal prior
void computeFocalPriorError(double *cam1,
  double *cam2, double *cam3, double *err)
{
  *err = cam1[FOCAL_IDX] - 2 * cam2[FOCAL_IDX]
    + cam3[FOCAL_IDX];
}

void computeZachWeightError(double *w, double *err)
{
  *err = 1 - (*w)*(*w);
}

void ba_objective(int n, int m, int p, double *cams, double *X,
  double *w, int *obs, double *feats,
  double *reproj_err, double *f_prior_err, double *w_err)
{
  int i, camIdx, ptIdx, idx1, idx2, idx3;

  for (i = 0; i < p; i++)
  {
    camIdx = obs[i * 2 + 0];
    ptIdx = obs[i * 2 + 1];
    computeReprojError(&cams[camIdx * BA_NCAMPARAMS], &X[ptIdx * 3],
      &w[i], feats[i * 2 + 0], feats[i * 2 + 1], &reproj_err[2 * i]);
  }

  for (i = 0; i < n - 2; i++)
  {
    idx1 = BA_NCAMPARAMS * i;
    idx2 = BA_NCAMPARAMS * (i + 1);
    idx3 = BA_NCAMPARAMS * (i + 2);
    computeFocalPriorError(&cams[idx1], &cams[idx2], &cams[idx3],
      &f_prior_err[i]);
  }

  for (i = 0; i < p; i++)
  {
    computeZachWeightError(&w[i], &w_err[i]);
  }

  // This term is here so that tapenade correctly 
  // recognizes inputs to be the inputs
  reproj_err[0] = reproj_err[0] + ((cams[0] - cams[0]) +
    (X[0] - X[0]) + (w[0] - w[0]));
}