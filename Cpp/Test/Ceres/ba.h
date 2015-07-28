#ifndef TEST_CERES_BA
#define TEST_CERES_BA

#include "ceres/ceres.h"
#include "ceres/rotation.h"

#define BA_NCAMPARAMS 11
#define FOCAL_IDX 6

// rad_params 2 radial distortion parameters
// proj 2 projection to be distorted
template<typename T>
void radial_distort(const T* const rad_params, T *proj)
{
	T rsq, L;
	rsq = proj[0] * proj[0] + proj[1] * proj[1];
	L = T(1) + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
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
void project(const T* const cam, const T* const X, T* proj)
{
	T Xo[3], Xcam[3];
	const T* const C = &cam[3];

	Xo[0] = X[0] - C[0];
	Xo[1] = X[1] - C[1];
	Xo[2] = X[2] - C[2];
	
	ceres::AngleAxisRotatePoint(cam, Xo, Xcam);

	proj[0] = Xcam[0] / Xcam[2];
	proj[1] = Xcam[1] / Xcam[2];

	radial_distort(&cam[9], proj);

	proj[0] = proj[0] * cam[6] + cam[7];
	proj[1] = proj[1] * cam[6] + cam[8];
}

template<typename T>
void computeReprojError(const T* const cam, 
	const T* const X, const T* const w, double feat_x, double feat_y,
	T* err)
{
	T proj[2];
	project(cam, X, proj);

	err[0] = (*w)*(proj[0] - T(feat_x));
	err[1] = (*w)*(proj[1] - T(feat_y));
}

// temporal prior
template<typename T>
void computeFocalPriorError(const T* const cam1, 
	const T* const cam2, const T* const cam3, T* err)
{
	*err = cam1[FOCAL_IDX] - T(2) * cam2[FOCAL_IDX] 
		+ cam3[FOCAL_IDX];
}

template<typename T>
void computeZachWeightError(const T* const w, T* err)
{
	*err = T(1) - (*w)*(*w);
}

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
void ba_objective(int n, int m, int p, double *cams, double *X, 
	double *w, int *obs, double *feats, double *reproj_err,
	double *f_prior_err, double *w_err)
{
	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[i * 2 + 0];
		int ptIdx = obs[i * 2 + 1];
		computeReprojError(&cams[camIdx * BA_NCAMPARAMS], &X[ptIdx * 3],
			&w[i], feats[i * 2 + 0], feats[i * 2 + 1], &reproj_err[2 * i]);
	}

	for (int i = 0; i < n-2; i++)
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

#endif //TEST_CERES_BA