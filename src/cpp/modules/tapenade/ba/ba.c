/*
 *   File "ba_b_tapenade_generated.c" is generated by Tapenade 3.14 (r7259) from this file.
 *   To reproduce such a generation you can use Tapenade CLI
 *   (can be downloaded from http://www-sop.inria.fr/tropics/tapenade/downloading.html)
 *
 *   After installing use the next command to generate a file:
 *
 *      tapenade -b -o ba_tapenade -head "compute_reproj_error(err)/(cam X) compute_zach_weight_error(err)/(w)" ba.c
 *
 *   This will produce a file "ba_tapenade_b.c" which content will be the same as the content of "ba_b_tapenade_generated.c",
 *   except one-line header. Moreover a log-file "ba_tapenade_b.msg" will be produced.
 *
 *   NOTE: the code in "ba_b_tapenade_generated.c" is wrong and won't work.
 *         REPAIRED SOURCE IS STORED IN THE FILE "ba_b.c".
 *         You can either use diff tool or read "ba_b.c" header to figure out what changes was performed to fix the code.
 *
 *   NOTE: you can also use Tapenade web server (http://tapenade.inria.fr:8080/tapenade/index.jsp)
 *         for generating but the result can be slightly different.
 */

#include "ba.h"

/* ===================================================================== */
/*                                UTILS                                  */
/* ===================================================================== */

double sqsum(int n, double const* x)
{
    int i;
    double res = 0;
    for (i = 0; i < n; i++)
    {
        res = res + x[i] * x[i];
    }

    return res;
}



void cross(double const* a, double const* b, double* out)
{
    out[0] = a[1] * b[2] - a[2] * b[1];
    out[1] = a[2] * b[0] - a[0] * b[2];
    out[2] = a[0] * b[1] - a[1] * b[0];
}



/* ===================================================================== */
/*                               MAIN LOGIC                              */
/* ===================================================================== */

// rot: 3 rotation parameters
// pt: 3 point to be rotated
// rotatedPt: 3 rotated point
// this is an efficient evaluation (part of
// the Ceres implementation)
// easy to understand calculation in matlab:
//  theta = sqrt(sum(w. ^ 2));
//  n = w / theta;
//  n_x = au_cross_matrix(n);
//  R = eye(3) + n_x*sin(theta) + n_x*n_x*(1 - cos(theta));    
void rodrigues_rotate_point(double const* rot, double const* pt, double *rotatedPt)
{
    int i;
    double sqtheta = sqsum(3, rot);
    if (sqtheta != 0)
    {
        double theta, costheta, sintheta, theta_inverse;
        double w[3], w_cross_pt[3], tmp;

        theta = sqrt(sqtheta);
        costheta = cos(theta);
        sintheta = sin(theta);
        theta_inverse = 1.0 / theta;

        for (i = 0; i < 3; i++)
        {
            w[i] = rot[i] * theta_inverse;
        }

        cross(w, pt, w_cross_pt);

        tmp = (w[0] * pt[0] + w[1] * pt[1] + w[2] * pt[2]) *
            (1. - costheta);

        for (i = 0; i < 3; i++)
        {
            rotatedPt[i] = pt[i] * costheta + w_cross_pt[i] * sintheta + w[i] * tmp;
        }
    }
    else
    {
        double rot_cross_pt[3];
        cross(rot, pt, rot_cross_pt);

        for (i = 0; i < 3; i++)
        {
            rotatedPt[i] = pt[i] + rot_cross_pt[i];
        }
    }
}


    
void radial_distort(double const* rad_params, double *proj)
{
    double rsq, L;
    rsq = sqsum(2, proj);
    L = 1. + rad_params[0] * rsq + rad_params[1] * rsq * rsq;
    proj[0] = proj[0] * L;
    proj[1] = proj[1] * L;
}

    

void project(double const* cam, double const* X, double* proj)
{
    double const* C = &cam[3];
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



// cam: 11 camera in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//            [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//            [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X: 3 point
// feats: 2 feature (x,y coordinates)
// reproj_err: 2
// projection function: 
// Xcam = R * (X - C)
// distorted = radial_distort(projective2euclidean(Xcam), radial_parameters)
// proj = distorted * f + principal_point
// err = sqsum(proj - measurement)
void compute_reproj_error(
    double const* cam,
    double const* X,
    double const* w,
    double const* feat,
    double *err
)
{
    double proj[2];
    project(cam, X, proj);

    err[0] = (*w)*(proj[0] - feat[0]);
    err[1] = (*w)*(proj[1] - feat[1]);
}

    

void compute_zach_weight_error(double const* w, double* err)
{
    *err = 1 - (*w)*(*w);
}

    

// n number of cameras
// m number of points
// p number of observations
// cams: 11*n cameras in format [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]
//            r1, r2, r3 are angle - axis rotation parameters(Rodrigues)
//            [C1 C2 C3]' is the camera center
//            f is the focal length in pixels
//            [u0 v0]' is the principal point
//            k1, k2 are radial distortion parameters
// X: 3*m points
// obs: 2*p observations (pairs cameraIdx, pointIdx)
// feats: 2*p features (x,y coordinates corresponding to observations)
// reproj_err: 2*p errors of observations
// w_err: p weight "error" terms
void ba_objective(
    int n,
    int m,
    int p,
    double const* cams,
    double const* X,
    double const* w,
    int const* obs,
    double const* feats,
    double* reproj_err,
    double* w_err
)
{
    int i;
    for (i = 0; i < p; i++)
    {
        int camIdx = obs[i * 2 + 0];
        int ptIdx = obs[i * 2 + 1];
        compute_reproj_error(
            &cams[camIdx * BA_NCAMPARAMS],
            &X[ptIdx * 3],
            &w[i],
            &feats[i * 2],
            &reproj_err[2 * i]
        );
    }

    for (i = 0; i < p; i++)
    {
        compute_zach_weight_error(&w[i], &w_err[i]);
    }
}