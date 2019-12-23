// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include "../../shared/defs.h"

#include "Eigen/Dense"
#include <vector>

using Eigen::ArrayXd;
using Eigen::MatrixXd;
using std::vector;

void Qtransposetimesx(int d,
    const double* const Ldiag,
    const double* const icf,
    const double* const x,
    double* Ltransposex);

void compute_q_inner_term(int d,
    const double* const Ldiag,
    const double* const xcentered,
    const double* const Lxcentered,
    double* logLdiag_d);

void compute_L_inner_term(int d,
    const double* const xcentered,
    const double* const Lxcentered,
    double* L_d);

double logsumexp_d(int n, const double* const x, double* logsumexp_partial_d);

double logsumexp_d(const ArrayXd& x, ArrayXd& logsumexp_partial_d);

double log_wishart_prior_d(int p, int k,
    Wishart wishart,
    const ArrayXd& sum_qs,
    const vector<MatrixXd>& Qs,
    const double* icf,
    double* J);