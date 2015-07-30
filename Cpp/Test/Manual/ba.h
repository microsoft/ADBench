#ifndef TEST_MANUAL_BA
#define TEST_MANUAL_BA

#define BA_NCAMPARAMS 11
#define BA_ROT_IDX 0
#define BA_C_IDX 3
#define BA_F_IDX 6
#define BA_X0_IDX 7
#define BA_RAD_IDX 9

void computeReprojError(const double *cam,
	const double *X, double w, double feat_x,
	double feat_y, double *err);
// J 2 x (BA_NCAMPARAMS+3+1) in column major
void computeReprojError_d(const double *cam,
	const double *X, double w, double feat_x,
	double feat_y, double *err, double *J);

// temporal prior
void computeFocalPriorError(double f1,
	double f2, double f3, double *err);
void computeFocalPriorError_d(double f1,
	double f2, double f3,
	double *err, double *J);

void computeZachWeightError(double w, double *err);
void computeZachWeightError_d(double w, double *err, double *J);

void ba_objective(int n, int m, int p, double *cams, double *X,
	double *w, int *obs, double *feats,
	double *reproj_err, double *f_prior_err, double *w_err);

#endif // TEST_MANUAL_BA