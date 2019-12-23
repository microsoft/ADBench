// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

// Arguments:
// cam - double[BA_NCAMPARAMS]
// X - double[3]
// w, feat_x, feat_y - double
// err - double[2]
// J - 2 x (BA_NCAMPARAMS+3+1) in column major
void compute_reproj_error_d(
  const double* const cam,
  const double* const X,
  double w, 
  double feat_x,
  double feat_y, 
  double *err, 
  double *J);

void compute_zach_weight_error_d(double w, double *err, double *J);