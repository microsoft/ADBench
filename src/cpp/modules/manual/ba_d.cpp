#include <cstring>
#include <cstdlib>
#include <cmath>
#include <cfloat>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"
#include "../../shared/ba.h" //clean c++ objective function
#include "ba_d.h"

void computeZachWeightError_d(double w, double* err, double* J)
{
	*err = 1 - w * w;
	*J = -2 * w;
}

// Expecting:
// v - double[3]
// M - double[9] (3x3 col-major matrix)
void set_cross_mat(
	const double * v,
	double * M)
{
	// M(0, 0) = 0.;	 M(0, 1) = -v(2); M(0, 2) = v(1);
	// M(1, 0) = v(2);  M(1, 1) = 0;     M(1, 2) = -v(0);
	// M(2, 0) = -v(1); M(2, 1) = v(0);  M(2, 2) = 0;
	M[0 * 3 + 0] = 0.;	  M[1 * 3 + 0] = -v[2]; M[2 * 3 + 0] = v[1];
	M[0 * 3 + 1] = v[2];  M[1 * 3 + 1] = 0.;    M[2 * 3 + 1] = -v[0];
	M[0 * 3 + 2] = -v[1]; M[1 * 3 + 1] = v[0];  M[2 * 3 + 2] = 0.;
}

// Expecting:
// vec - double[3]
double vec3dSquaredNorm(const double* vec)
{
	double x0 = vec[0];
	double x1 = vec[1];
	double x2 = vec[2];
	return x0 * x0 + x1 * x1 + x2 * x2;
}

// Expecting:
// source - double[3]
// factor - double
// result - double[3]
void scaleVec3d(const double* source, double factor, double* result)
{
	result[0] = source[0] * factor;
	result[1] = source[1] * factor;
	result[2] = source[2] * factor;
}

// Expecting:
// x - double[3]
// y - double[3]
// result - double[9] (3x3 col-major matrix)
void mulColRow3d(const double* x, const double* y, double* result)
{
	double x0 = x[0];
	double x1 = x[1];
	double x2 = x[2];
	double y0 = y[0];
	double y1 = y[1];
	double y2 = y[2];
	result[0 * 3 + 0] = x0 * y0;    result[1 * 3 + 0] = x0 * y1;    result[2 * 3 + 0] = x0 * y2;
	result[0 * 3 + 1] = x1 * y0;    result[1 * 3 + 1] = x1 * y1;    result[2 * 3 + 1] = x1 * y2;
	result[0 * 3 + 2] = x2 * y0;    result[1 * 3 + 2] = x2 * y1;    result[2 * 3 + 2] = x2 * y2;
}

// Expecting:
// x - double[3]
// M - double[9] (3x3 col-major matrix)
// result - double[9] (3x3 col-major matrix)
void mulRowMat3d(const double* x, const double* M, double* result)
{
	double x0 = x[0];
	double x1 = x[1];
	double x2 = x[2];
	result[0] = x0 * M[0 * 3 + 0] + x1 * M[0 * 3 + 1] + x2 * M[0 * 3 + 2];
	result[1] = x0 * M[1 * 3 + 0] + x1 * M[1 * 3 + 1] + x2 * M[1 * 3 + 2];
	result[2] = x0 * M[2 * 3 + 2] + x1 * M[2 * 3 + 2] + x2 * M[2 * 3 + 2];
}

// Expecting:
// M - double[9] (3x3 col-major matrix)
// x - double[3]
// result - double[9] (3x3 col-major matrix)
void mulMatCol3d(const double* M, const double* x, double* result)
{
	double x0 = x[0];
	double x1 = x[1];
	double x2 = x[2];
	result[0] = M[0 * 3 + 0] * x0 + M[1 * 3 + 0] * x1 + M[2 * 3 + 0] * x2;
	result[1] = M[0 * 3 + 1] * x0 + M[1 * 3 + 1] * x1 + M[2 * 3 + 1] * x2;
	result[2] = M[0 * 3 + 2] * x0 + M[1 * 3 + 2] * x1 + M[2 * 3 + 2] * x2;
}

// Expecting:
// x - double[9] (3x3 col-major matrix)
// y - double[9] (3x3 col-major matrix)
// result - double[9] (3x3 col-major matrix)
void mulMat3d(const double* x, const double* y, double* result)
{
	for (int i = 0; i < 3; ++i)
	{
		for (int j = 0; j < 3; ++j)
		{
			double rij = 0;
			for (int k = 0; k < 3; ++k)
			{
				rij += x[k * 3 + i] * y[j * 3 + k];
			}
			result[j * 3 + i] = rij;
		}
	}
}

// Expecting:
// x - double[6] (2x3 col-major matrix)
// y - double[9] (3x3 col-major matrix)
// result - double[6] (2x3 col-major matrix)
void mulMat23dBy3d(const double* x, const double* y, double* result)
{
	for (int i = 0; i < 2; ++i)
	{
		for (int j = 0; j < 3; ++j)
		{
			double rij = 0;
			for (int k = 0; k < 3; ++k)
			{
				rij += x[k * 2 + i] * y[j * 3 + k];
			}
			result[j * 2 + i] = rij;
		}
	}
}

void addToVec3d(double* x, const double* y)
{
	x[0] += y[0];
	x[1] += y[1];
	x[2] += y[2];
}

double dot3d(const double* x, const double* y)
{
	return x[0] * y[0] + x[1] * y[1] + x[2] * y[2];
}

// const Vector3d& rot,
// const Vector3d& X,
// Vector3d& rotatedX,
// Matrix3d& rodri_rot_d,
// Matrix3d& rodri_X_d)
void rodrigues_rotate_point_d(
	const double * rot,
	const double * X,
	double * rotatedX,
	double * rodri_rot_d,
	double * rodri_X_d)
{
	double sqtheta = vec3dSquaredNorm(rot);
	if (sqtheta != 0.)
	{
		double w[3], w_cross_X[3], acc[3], acc2[3]; // Vector3d
		double /*theta_d[3],*/ tmp_d[3], theta_d_scaled[3], x_scaled[3]; // RowVector3d
		double w_d[9], M[9], X_cross[9], accm[9]; // Matrix3d
		double theta = sqrt(sqtheta);

		double costheta = cos(theta);
		double sintheta = sin(theta);
		double theta_inverse = 1.0 / theta;

		scaleVec3d(rot, theta_inverse, w); // w_d = -rot*theta_d*(theta_inverse*theta_inverse);
		//theta_d = w; // w.transpose()

		scaleVec3d(w, -theta_inverse * theta_inverse, tmp_d);
		mulColRow3d(rot, tmp_d, w_d); // w_d = -rot * theta_d * (theta_inverse * theta_inverse);
		for (int i = 0; i < 3; i++)
			w_d[i * 3 + i] += theta_inverse;

		w_cross_X[0] = w[1] * X[2] - w[2] * X[1];
		w_cross_X[1] = w[2] * X[0] - w[0] * X[2];
		w_cross_X[2] = w[0] * X[1] - w[1] * X[0];

		double w_dot_X = dot3d(w, X); // w.dot(X);
		double tmp = (1. - costheta) * (w_dot_X);
		scaleVec3d(X, 1. - costheta, x_scaled);
		mulRowMat3d(x_scaled, w_d, tmp_d);
		scaleVec3d(w, w_dot_X * sintheta, theta_d_scaled);
		addToVec3d(tmp_d, theta_d_scaled);
		/*tmp_d.noalias() = (1. - costheta) * X.transpose() * w_d +
			w_dot_X * sintheta * theta_d;*/

		scaleVec3d(X, costheta, rotatedX);
		scaleVec3d(w_cross_X, sintheta, acc);
		addToVec3d(rotatedX, acc);
		scaleVec3d(w, tmp, acc);
		addToVec3d(rotatedX, acc);
		//rotatedX.noalias() = costheta * X + sintheta * w_cross_X + tmp * w;

		set_cross_mat(X, M);
		for (int i = 0; i < 9; ++i)
			M[i] *= -sintheta;
		//M *= -sintheta;
		for (int i = 0; i < 3; i++)
			M[i * 3 + i] = tmp;

		scaleVec3d(w_cross_X, costheta, acc);
		scaleVec3d(X, -sintheta, acc2);
		addToVec3d(acc, acc2);
		mulColRow3d(acc, w, rodri_rot_d);
		mulMat3d(M, w_d, accm);
		for (int i = 0; i < 9; ++i)
			rodri_rot_d[i] += accm[i];
		mulColRow3d(w, tmp_d, accm);
		for (int i = 0; i < 9; ++i)
			rodri_rot_d[i] += accm[i];
		/*rodri_rot_d.noalias() = (costheta * w_cross_X - sintheta * X) * theta_d +
			M * w_d + w * tmp_d;*/

		set_cross_mat(w, X_cross);
		for (int i = 0; i < 9; ++i)
			rodri_X_d[i] = X_cross[i] * sintheta;
		scaleVec3d(w, 1. - costheta, acc);
		mulColRow3d(acc, w, accm);
		for (int i = 0; i < 9; ++i)
			rodri_X_d[i] += accm[i];
		//rodri_X_d.noalias() = sintheta * X_cross + (1. - costheta) * w * w.transpose();
		for (int i = 0; i < 3; i++)
			rodri_X_d[i * 3 + i] += costheta;
	}
	else
	{
		set_cross_mat(X, rodri_rot_d);
		for (int i = 0; i < 9; ++i)
			rodri_rot_d[i] *= -1;
		//rodri_rot_d *= -1;
		/*Matrix3d rot_cross;
		set_cross_mat(rot, rot_cross);
		rotatedX.noalias() = X + rot_cross * X;
		rodri_X_d = Matrix3d::Identity() + rot_cross;*/
		set_cross_mat(rot, rodri_X_d);
		mulMatCol3d(rodri_X_d, X, rotatedX);
		addToVec3d(rotatedX, X);
		for (int i = 0; i < 3; i++)
			rodri_X_d[i * 3 + i] += 1;
	}
}


// const Vector2d& rad_params,
// Vector2d& proj,
// Matrix2d& distort_proj_d,
// Matrix2d& distort_rad_d)
void radial_distort_d(
	const double* rad_params,
	double* proj,
	double* distort_proj_d,
	double* distort_rad_d)
{
	double rsq = proj[0] * proj[0] + proj[1] + proj[1];// proj.squaredNorm();
	double L = 1 + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
	double distort_proj_d_coef = 2 * rad_params[0] + 4 * rad_params[1] * rsq;
	distort_proj_d[0 * 2 + 0] = distort_proj_d_coef * proj[0] * proj[0] + L;
	distort_proj_d[1 * 2 + 0] = distort_proj_d_coef * proj[0] * proj[1];
	distort_proj_d[0 * 2 + 1] = distort_proj_d_coef * proj[1] * proj[0];
	distort_proj_d[1 * 2 + 1] = distort_proj_d_coef * proj[1] * proj[1] + L;
	/*distort_proj_d.noalias() = (2 * rad_params[0] + 4 * rad_params[1] * rsq) *
		proj * proj.transpose();
	distort_proj_d(0, 0) += L;
	distort_proj_d(1, 1) += L;*/
	distort_rad_d[0 * 2 + 0] = rsq * proj[0];
	distort_rad_d[0 * 2 + 1] = rsq * proj[1];
	// distort_rad_d.col(0) = proj * rsq;
	distort_rad_d[1 * 2 + 0] = rsq * distort_rad_d[0 * 2 + 0];
	distort_rad_d[1 * 2 + 1] = rsq * distort_rad_d[0 * 2 + 1];
	//distort_rad_d.col(1) = distort_rad_d.col(0) * rsq;
	proj[0] *= L;
	proj[1] *= L;
}

// const double* const cam,
// const Vector3d& X,
// Vector2d& proj,
// double* J
void project_d(
	const double* const cam,
	const double* const X,
	double* proj,
	double* J)
{
	double Xo[3], Xcam[3];
	const double* const rot = &cam[BA_ROT_IDX];
	const double* const C = &cam[BA_C_IDX];
	double f = cam[BA_F_IDX];
	const double* const x0 = &cam[BA_X0_IDX];
	const double* const rad = &cam[BA_RAD_IDX];

	double* Jrot = &J[2 * BA_ROT_IDX];
	double* JC = &J[2 * BA_C_IDX];
	double* Jf = &J[2 * BA_F_IDX];
	double* Jx0 = &J[2 * BA_X0_IDX];
	double* Jrad = &J[2 * BA_RAD_IDX];
	double* JX = &J[2 * BA_NCAMPARAMS];

	subtract(3, X, C, Xo);

	double rodri_rot_d[9], rodri_Xo_d[9];
	rodrigues_rotate_point_d(rot, Xo, Xcam, rodri_rot_d,
		rodri_Xo_d);

	p2e(Xcam, proj);

	double distort_proj_d[4], distort_rad_d[4];
	radial_distort_d(rad, proj, distort_proj_d, distort_rad_d);

	double hnorm_right_col[2];
	double tmp = 1. / (Xcam[2] * Xcam[2]);
	hnorm_right_col[0] = -Xcam[0] * tmp;
	hnorm_right_col[1] = -Xcam[1] * tmp;
	double distort_hnorm_d[6];

	for (int i = 0; i < 4; i++)
		distort_hnorm_d[i] = distort_proj_d[i] / Xcam[2];
	// distort_hnorm_d.col(2).noalias() = distort_proj_d*hnorm_right_col;
	distort_hnorm_d[2 * 2 + 0] = distort_proj_d[0 * 2 + 0] * hnorm_right_col[0] + distort_proj_d[1 * 2 + 0] * hnorm_right_col[1];
	distort_hnorm_d[2 * 2 + 1] = distort_proj_d[0 * 2 + 1] * hnorm_right_col[0] + distort_proj_d[1 * 2 + 1] * hnorm_right_col[1];
	//multiply(2, 2, 1, distort_proj_d, hnorm_right_col, &distort_hnorm_d[4]);

	mulMat23dBy3d(distort_hnorm_d, rodri_rot_d, Jrot);
	for (int i = 0; i < 6; ++i)
		Jrot[i] *= f;
	//Jrot.noalias() = f * distort_hnorm_d * rodri_rot_d;

	mulMat23dBy3d(distort_hnorm_d, rodri_Xo_d, JC);
	for (int i = 0; i < 6; ++i)
		JC[i] *= -f;
	//JC.noalias() = (-f) * distort_hnorm_d * rodri_Xo_d;
	Jf[0] = proj[0];
	Jf[1] = proj[1];
	// Jf = proj;
	Jx0[0] = 1.;
	Jx0[1] = 0.;
	Jx0[2] = 0.;
	Jx0[3] = 1.;
	//Jx0.setIdentity();
	for (int i = 0; i < 4; ++i)
		Jrad[i] = distort_rad_d[i] * f;
	//Jrad = distort_rad_d * f;
	for (int i = 0; i < 6; ++i)
		JX[i] = -JC[i];
	//JX = -JC;

	proj[0] = proj[0] * f + x0[0];
	proj[1] = proj[1] * f + x0[1];
	//proj = proj * f + x0;
}

void computeReprojError_d(
	const double* const cam,
	const double* const X,
	double w,
	double feat_x,
	double feat_y,
	double* err,
	double* J)
{
	double proj[2];
	project_d(cam, X, proj, J);

	int Jw_idx = 2 * (BA_NCAMPARAMS + 3);
	J[Jw_idx + 0] = (proj[0] - feat_x);
	J[Jw_idx + 1] = (proj[1] - feat_y);
	err[0] = w * J[Jw_idx + 0];
	err[1] = w * J[Jw_idx + 1];
	for (int i = 0; i < 2 * (BA_NCAMPARAMS + 3); i++)
	{
		J[i] *= w;
	}
}