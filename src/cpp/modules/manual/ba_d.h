#pragma once

// J 2 x (BA_NCAMPARAMS+3+1) in column major
void computeReprojError_d(
  const double* const cam,
  const double* const X,
  double w, 
  double feat_x,
  double feat_y, 
  double *err, 
  double *J);

void computeZachWeightError_d(double w, double *err, double *J);