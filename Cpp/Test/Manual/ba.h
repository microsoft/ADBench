#ifndef TEST_MANUAL_BA
#define TEST_MANUAL_BA

void computeReprojError(
  const double* const cam,
  const double* const X,
  double w, 
  double feat_x,
  double feat_y, 
  double *err);
// J 2 x (BA_NCAMPARAMS+3+1) in column major
void computeReprojError_d(
  const double* const cam,
  const double* const X,
  double w, 
  double feat_x,
  double feat_y, 
  double *err, 
  double *J);

void computeZachWeightError(double w, double *err);
void computeZachWeightError_d(double w, double *err, double *J);

void ba_objective(int n, int m, int p, 
  const double* const cams, 
  const double* const X,
  const double* const w, 
  const int* const obs, 
  const double* const feats,
  double *reproj_err, 
  double *w_err);

#endif // TEST_MANUAL_BA