#include "ba.h"

#include <stdlib.h>
#include <math.h>
#include <float.h>

// rot 3 rotation parameters
// R 3*3 rotation matrix (column major)
// easy to understand calculation in matlab:
//	theta = sqrt(sum(w. ^ 2));
//	n = w / theta;
//	n_x = au_cross_matrix(n);
//	R = eye(3) + n_x*sin(theta) + n_x*n_x*(1 - cos(theta));
void rodrigues_rot(adouble *rot, adouble *R)
{
	adouble w1, w2, w3, t2, t3, t4, t5, t6, t7, t8,
		t9, t10, t11, t12, t13, t14, t15, t17, t23, t32;

	w1 = rot[0];
	w2 = rot[1];
	w3 = rot[2];

	t2 = w2*w2;
	t3 = w1*w1;
	t4 = w3*w3;
	t5 = t2 + t3 + t4 + DBL_EPSILON;

	t7 = sqrt(t5);
	t8 = cos(t7);
	t10 = sin(t7);
	t9 = t8 - 1.0;
	t11 = 1. / t7;
	t13 = t10*t11*w2;

	t6 = 1. / t5;
	t12 = t4*t6;
	t14 = t3*t6;
	t15 = t2*t6;
	t17 = t12 + t15;
	t23 = t12 + t14;
	t32 = t14 + t15;

	// first row
	R[0 * 3 + 0] = t9*t17 + 1.;
	R[1 * 3 + 0] = -t10*t11*w3 - t6*t9*w1*w2;
	R[2 * 3 + 0] = t13 - t6*t9*w1*w3;

	// second row
	R[0 * 3 + 1] = t10*t11*w3 - t6*t9*w1*w2;
	R[1 * 3 + 1] = t9*t23 + 1.0;
	R[2 * 3 + 1] = -t10*t11*w1 - t6*t9*w2*w3;

	// third row
	R[0 * 3 + 2] = -t13 - t6*t9*w1*w3;
	R[1 * 3 + 2] = t10*t11*w1 - t6*t9*w2*w3;
	R[2 * 3 + 2] = t9*t32 + 1.0;
}

// rad_params 2 radial distortion parameters
// proj 2 projection to be distorted
void radial_distort(adouble *rad_params, adouble *proj)
{
	adouble rsq, L;
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
// R 3*3 column major rotation matrix
// X 3 point
// proj 2 projection
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void project(adouble *cam, adouble *R, adouble *X, adouble *proj)
{
	adouble *C;
	adouble Xo[3], Xcam[3];
	C = &cam[3];

	Xo[0] = X[0] - C[0];
	Xo[1] = X[1] - C[1];
	Xo[2] = X[2] - C[2];

	Xcam[0] = 0.;
	Xcam[1] = 0.;
	Xcam[2] = 0.;
	int Ridx = 0;
	for (int i = 0; i < 3; i++)
	{
		for (int k = 0; k < 3; k++)
		{
			Xcam[k] = Xcam[k] + R[Ridx] * Xo[i];
			Ridx = Ridx + 1;
		}
	}

	proj[0] = Xcam[0] / Xcam[2];
	proj[1] = Xcam[1] / Xcam[2];

	radial_distort(&cam[9], proj);

	proj[0] = proj[0] * cam[6] + cam[7];
	proj[1] = proj[1] * cam[6] + cam[8];
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
// err p squared errors of observations
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void ba(int n, int m, int p, adouble *cams, adouble *X, int *obs, double *feats,
	adouble *err)
{
	adouble *R = new adouble[3 * 3 * n];
	adouble *proj = new adouble[2];
	int nCamParams = 11;
	for (int i = 0; i < n; i++)
	{
		rodrigues_rot(&cams[i*nCamParams], &R[i * 3 * 3]);
	}

	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[i * 2 + 0];
		int ptIdx = obs[i * 2 + 1];
		project(&cams[camIdx * nCamParams], &R[camIdx * 3 * 3], &X[ptIdx * 3], proj);
		proj[0] = proj[0] - feats[i * 2 + 0];
		proj[1] = proj[1] - feats[i * 2 + 1];
		err[i] = proj[0] * proj[0] + proj[1] * proj[1];
	}

	delete[] R;
	delete[] proj;
}

// rot 3 rotation parameters
// R 3*3 rotation matrix (column major)
// easy to understand calculation in matlab:
//	theta = sqrt(sum(w. ^ 2));
//	n = w / theta;
//	n_x = au_cross_matrix(n);
//	R = eye(3) + n_x*sin(theta) + n_x*n_x*(1 - cos(theta));
void rodrigues_rot(double *rot, double *R)
{
	double w1, w2, w3, t2, t3, t4, t5, t6, t7, t8,
		t9, t10, t11, t12, t13, t14, t15, t17, t23, t32;

	w1 = rot[0];
	w2 = rot[1];
	w3 = rot[2];

	t2 = w2*w2;
	t3 = w1*w1;
	t4 = w3*w3;
	t5 = t2 + t3 + t4 + DBL_EPSILON;

	t7 = sqrt(t5);
	t8 = cos(t7);
	t10 = sin(t7);
	t9 = t8 - 1.0;
	t11 = 1. / t7;
	t13 = t10*t11*w2;

	t6 = 1. / t5;
	t12 = t4*t6;
	t14 = t3*t6;
	t15 = t2*t6;
	t17 = t12 + t15;
	t23 = t12 + t14;
	t32 = t14 + t15;

	// first row
	R[0 * 3 + 0] = t9*t17 + 1.;
	R[1 * 3 + 0] = -t10*t11*w3 - t6*t9*w1*w2;
	R[2 * 3 + 0] = t13 - t6*t9*w1*w3;

	// second row
	R[0 * 3 + 1] = t10*t11*w3 - t6*t9*w1*w2;
	R[1 * 3 + 1] = t9*t23 + 1.0;
	R[2 * 3 + 1] = -t10*t11*w1 - t6*t9*w2*w3;

	// third row
	R[0 * 3 + 2] = -t13 - t6*t9*w1*w3;
	R[1 * 3 + 2] = t10*t11*w1 - t6*t9*w2*w3;
	R[2 * 3 + 2] = t9*t32 + 1.0;
}

// rad_params 2 radial distortion parameters
// proj 2 projection to be distorted
void radial_distort(double *rad_params, double *proj)
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
// R 3*3 column major rotation matrix
// X 3 point
// proj 2 projection
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void project(double *cam, double *R, double *X, double *proj)
{
	double *C;
	double Xo[3], Xcam[3];
	C = &cam[3];

	Xo[0] = X[0] - C[0];
	Xo[1] = X[1] - C[1];
	Xo[2] = X[2] - C[2];

	Xcam[0] = 0.;
	Xcam[1] = 0.;
	Xcam[2] = 0.;
	int Ridx = 0;
	for (int i = 0; i < 3; i++)
	{
		for (int k = 0; k < 3; k++)
		{
			Xcam[k] = Xcam[k] + R[Ridx] * Xo[i];
			Ridx = Ridx + 1;
		}
	}

	proj[0] = Xcam[0] / Xcam[2];
	proj[1] = Xcam[1] / Xcam[2];

	radial_distort(&cam[9], proj);

	proj[0] = proj[0] * cam[6] + cam[7];
	proj[1] = proj[1] * cam[6] + cam[8];
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
// err p squared errors of observations
// projection: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void ba(int n, int m, int p, double *cams, double *X, int *obs, double *feats,
	double *err)
{
	double *R = new double[3 * 3 * n];
	double *proj = new double[2];
	int nCamParams = 11;
	for (int i = 0; i < n; i++)
	{
		rodrigues_rot(&cams[i*nCamParams], &R[i * 3 * 3]);
	}

	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[i * 2 + 0];
		int ptIdx = obs[i * 2 + 1];
		project(&cams[camIdx * nCamParams], &R[camIdx * 3 * 3], &X[ptIdx * 3], proj);
		proj[0] = proj[0] - feats[i * 2 + 0];
		proj[1] = proj[1] - feats[i * 2 + 1];
		err[i] = proj[0] * proj[0] + proj[1] * proj[1];
	}

	delete[] R;
	delete[] proj;
}