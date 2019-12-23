// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "gmm_d.h"

#include <cmath>
#include <vector>
#include <algorithm>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"

using std::vector;

#include "../../shared/gmm.h"

void Qtransposetimesx(int d,
    const double* const Ldiag,
    const double* const icf,
    const double* const x,
    double* Ltransposex)
{
    int Lparamsidx = d;
    for (int i = 0; i < d; i++)
        Ltransposex[i] = Ldiag[i] * x[i];

    for (int i = 0; i < d; i++)
        for (int j = i + 1; j < d; j++)
        {
            Ltransposex[i] += icf[Lparamsidx] * x[j];
            Lparamsidx++;
        }
}

void compute_q_inner_term(int d,
    const double* const Ldiag,
    const double* const xcentered,
    const double* const Lxcentered,
    double* logLdiag_d)
{
    for (int i = 0; i < d; i++)
    {
        logLdiag_d[i] = 1. - Ldiag[i] * xcentered[i] * Lxcentered[i];
    }
}

void compute_L_inner_term(int d,
    const double* const xcentered,
    const double* const Lxcentered,
    double* L_d)
{
    int Lparamsidx = 0;
    for (int i = 0; i < d; i++)
    {
        int n_curr_elems = d - i - 1;
        for (int j = 0; j < n_curr_elems; j++)
        {
            L_d[Lparamsidx] = -xcentered[i] * Lxcentered[d - n_curr_elems + j];
            Lparamsidx++;
        }
    }
}

double logsumexp_d(int n, const double* const x, double *logsumexp_partial_d)
{
    int max_elem = arr_max_idx(n, x);
    double mx = x[max_elem];
    double semx = 0.;
    for (int i = 0; i < n; i++)
    {
        logsumexp_partial_d[i] = exp(x[i] - mx);
        semx += logsumexp_partial_d[i];
    }
    if (semx == 0.)
    {
        std::fill(logsumexp_partial_d, logsumexp_partial_d + n, 0.0);
    }
    else
    {
        logsumexp_partial_d[max_elem] -= semx;
        for (int i = 0; i < n; i++)
            logsumexp_partial_d[i] /= semx;
    }
    logsumexp_partial_d[max_elem] += 1.;
    return log(semx) + mx;
}

void gmm_objective_d(int d, int k, int n,
    const double *alphas,
    const double *means,
    const double *icf,
    const double *x,
    Wishart wishart,
    double *err,
    double *J)
{
    const double CONSTANT = -n * d*0.5*log(2 * PI);
    int icf_sz = d * (d + 1) / 2;

    vector<double> Qdiags(d*k);
    vector<double> sum_qs(k);
    vector<double> main_term(k);
    vector<double> xcentered(d);
    vector<double> Qxcentered(d);

    preprocess_qs(d, k, icf, sum_qs.data(), Qdiags.data());

    std::fill(J, J + (k + d * k + icf_sz * k), 0.0);

    vector<double> curr_means_d(d*k);
    vector<double> curr_q_d(d*k);
    vector<double> curr_L_d((icf_sz - d) * k);

    double *alphas_d = J;
    double *means_d = &J[k];
    double *icf_d = &J[k + d * k];

    double slse = 0.;
    for (int ix = 0; ix < n; ix++)
    {
        const double* const curr_x = &x[ix*d];
        for (int ik = 0; ik < k; ik++)
        {
            int icf_off = ik * icf_sz;
            double *Qdiag = &Qdiags[ik*d];

            subtract(d, curr_x, &means[ik*d], xcentered.data());
            Qtimesx(d, Qdiag, &icf[ik*icf_sz + d], xcentered.data(), Qxcentered.data());
            Qtransposetimesx(d, Qdiag, &icf[icf_off], Qxcentered.data(), &curr_means_d[ik*d]);
            compute_q_inner_term(d, Qdiag, xcentered.data(), Qxcentered.data(), &curr_q_d[ik*d]);
            compute_L_inner_term(d, xcentered.data(), Qxcentered.data(), &curr_L_d[ik*(icf_sz - d)]);
            main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5*sqnorm(d, Qxcentered.data());
        }
        slse += logsumexp_d(k, main_term.data(), main_term.data());
        for (int ik = 0; ik < k; ik++)
        {
            int means_off = ik * d;
            int icf_off = ik * icf_sz;
            alphas_d[ik] += main_term[ik];
            for (int id = 0; id < d; id++)
            {
                means_d[means_off + id] += curr_means_d[means_off + id] * main_term[ik];
                icf_d[icf_off + id] += curr_q_d[ik*d + id] * main_term[ik];
            }
            for (int i = d; i < icf_sz; i++)
            {
                icf_d[icf_off + i] += curr_L_d[ik*(icf_sz - d) + (i - d)] * main_term[ik];
            }
        }
    }

    vector<double> lse_alphas_d(k);
    double lse_alphas = logsumexp_d(k, alphas, lse_alphas_d.data());
    for (int ik = 0; ik < k; ik++)
    {
        alphas_d[ik] -= n * lse_alphas_d[ik];
        for (int id = 0; id < d; id++)
        {
            icf_d[ik*icf_sz + id] += wishart.gamma*wishart.gamma * Qdiags[ik*d + id] * Qdiags[ik*d + id]
                - wishart.m;
        }
        for (int i = d; i < icf_sz; i++)
        {
            icf_d[ik*icf_sz + i] += wishart.gamma*wishart.gamma*icf[ik*icf_sz + i];
        }
    }

    *err = CONSTANT + slse - n * lse_alphas;
    *err += log_wishart_prior(d, k, wishart, sum_qs.data(), Qdiags.data(), icf);
}