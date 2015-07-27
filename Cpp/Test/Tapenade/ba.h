
#include "adStack.h"
#include "../defs.h"

void rodrigues_rot(double *rot, double *R);
void radial_distort(double *rad_params, double *proj);
void project(double *cam, double *R, double *X, double *proj);

void ba(int n, int m, int p, double *cams, double *X, int *obs, double *feats,
	double *err);

void ba_d(int n, int m, int p, double *cams, double *camsd, double *X, double
	*Xd, int *obs, double *feats, double *err, double *errd);

void ba_b(int n, int m, int p, double *cams, double *camsb, double *X, double
	*Xb, int *obs, double *feats, double *err, double *errb);


void ba_dv(int n, int m, int p, double *cams, double(*camsd)[NBDirsMax],
	double *X, double(*Xd)[NBDirsMax], int *obs, double *feats, double *
	err, double(*errd)[NBDirsMax], int nbdirs);
void ba_bv(int n, int m, int p, double *cams, double(*camsb)[NBDirsMax],
	double *X, double(*Xb)[NBDirsMax], int *obs, double *feats, double *
	err, double(*errb)[NBDirsMax], int nbdirs);