#pragma once

#include "../../shared/defs.h"

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
