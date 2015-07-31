#include "ba.h"
#include <stdlib.h>
#include <math.h>
#include <float.h>

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
void rodrigues_rotate_point(const adouble *rot, const adouble *pt,
	adouble *rotatedPt)
{
	adouble theta, costheta, sintheta, theta_inverse,
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
void radial_distort(const adouble *rad_params, adouble *proj)
{
	adouble rsq, L;
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
void project(const adouble *cam, const adouble *X, adouble *proj)
{
	const adouble *C = &cam[3];
	adouble Xo[3], Xcam[3];

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

void computeReprojError(const adouble *cam,
	const adouble *X, const adouble *w, const double *feat,
	adouble *err)
{
	adouble proj[2];
	project(cam, X, proj);

	err[0] = (*w)*(proj[0] - feat[0]);
	err[1] = (*w)*(proj[1] - feat[1]);
}

// temporal prior
void computeFocalPriorError(const adouble *cam1,
	const adouble *cam2, const adouble *cam3, adouble *err)
{
	*err = cam1[BA_F_IDX] - 2 * cam2[BA_F_IDX]
		+ cam3[BA_F_IDX];
}

void computeZachWeightError(const adouble *w, adouble *err)
{
	*err = 1 - (*w)*(*w);
}

void ba_objective(int n, int m, int p, const adouble *cams,
	const adouble *X, const adouble *w, const int *obs,
	const double *feats, adouble *reproj_err,
	adouble *f_prior_err, adouble *w_err)
{
	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[i * 2 + 0];
		int ptIdx = obs[i * 2 + 1];
		computeReprojError(&cams[camIdx * BA_NCAMPARAMS], &X[ptIdx * 3],
			&w[i], &feats[i * 2], &reproj_err[2 * i]);
	}

	for (int i = 0; i < n - 2; i++)
	{
		int idx1 = BA_NCAMPARAMS * i;
		int idx2 = BA_NCAMPARAMS * (i + 1);
		int idx3 = BA_NCAMPARAMS * (i + 2);
		computeFocalPriorError(&cams[idx1], &cams[idx2], &cams[idx3],
			&f_prior_err[i]);
	}

	for (int i = 0; i < p; i++)
	{
		computeZachWeightError(&w[i], &w_err[i]);
	}
}

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
void rodrigues_rotate_point(const double *rot, const double *pt, 
	double *rotatedPt)
{
	double theta, costheta, sintheta, theta_inverse,
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
void radial_distort(const double *rad_params, double *proj)
{
	double rsq, L;
	rsq = proj[0] * proj[0] + proj[1] * proj[1];
	L = 1 + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
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
void project(const double *cam, const double *X, double *proj)
{
	const double *C = &cam[3];
	double Xo[3], Xcam[3];

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

void computeReprojError(const double *cam,
	const double *X, const double *w, const double *feat,
	double *err)
{
	double proj[2];
	project(cam, X, proj);

	err[0] = (*w)*(proj[0] - feat[0]);
	err[1] = (*w)*(proj[1] - feat[1]);
}

// temporal prior
void computeFocalPriorError(const double *cam1,
	const double *cam2, const double *cam3, double *err)
{
	*err = cam1[BA_F_IDX] - 2 * cam2[BA_F_IDX]
		+ cam3[BA_F_IDX];
}

void computeZachWeightError(const double *w, double *err)
{
	*err = 1 - (*w)*(*w);
}

void ba_objective(int n, int m, int p, const double *cams, 
	const double *X,const double *w, const int *obs, 
	const double *feats,double *reproj_err, 
	double *f_prior_err, double *w_err)
{
	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[i * 2 + 0];
		int ptIdx = obs[i * 2 + 1];
		computeReprojError(&cams[camIdx * BA_NCAMPARAMS], &X[ptIdx * 3],
			&w[i], &feats[i * 2], &reproj_err[2 * i]);
	}

	for (int i = 0; i < n - 2; i++)
	{
		int idx1 = BA_NCAMPARAMS * i;
		int idx2 = BA_NCAMPARAMS * (i + 1);
		int idx3 = BA_NCAMPARAMS * (i + 2);
		computeFocalPriorError(&cams[idx1], &cams[idx2], &cams[idx3],
			&f_prior_err[i]);
	}

	for (int i = 0; i < p; i++)
	{
		computeZachWeightError(&w[i], &w_err[i]);
	}
}