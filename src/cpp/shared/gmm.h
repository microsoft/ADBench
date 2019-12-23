// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <cmath>
#include <vector>
using std::vector;
#include "defs.h"
#include "matrix.h"

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// d: dim
// k: number of gaussians
// n: number of points
// alphas: k logs of mixture weights (unnormalized), so
//          weights = exp(log_alphas) / sum(exp(log_alphas))
// means: d*k component means
// icf: (d*(d+1)/2)*k inverse covariance factors 
//                  every icf entry stores firstly log of diagonal and then 
//          columnwise other entris
//          To generate icf in MATLAB given covariance C :
//              L = inv(chol(C, 'lower'));
//              inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
// wishart: wishart distribution parameters
// x: d*n points
// err: 1 output
template<typename T>
void gmm_objective(int d, int k, int n, const T* const alphas, const T* const means,
    const T* const icf, const double* const x, Wishart wishart, T* err);

// split of the outer loop over points
template<typename T>
void gmm_objective_split_inner(int d, int k,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    const double* const x,
    Wishart wishart,
    T* err);
// other terms which are outside the loop
template<typename T>
void gmm_objective_split_other(int d, int k, int n,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    Wishart wishart,
    T* err);

template<typename T>
T logsumexp(int n, const T* const x);

// p: dim
// k: number of components
// wishart parameters
// sum_qs: k sums of log diags of Qs
// Qdiags: d*k
// icf: (p*(p+1)/2)*k inverse covariance factors
template<typename T>
T log_wishart_prior(int p, int k,
    Wishart wishart,
    const T* const sum_qs,
    const T* const Qdiags,
    const T* const icf);

template<typename T>
void preprocess_qs(int d, int k,
    const T* const icf,
    T* sum_qs,
    T* Qdiags);

template<typename T>
void Qtimesx(int d,
    const T* const Qdiag,
    const T* const ltri, // strictly lower triangular part
    const T* const x,
    T* out);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

template<typename T>
T logsumexp(int n, const T* const x)
{
    T mx = arr_max(n, x);
    T semx = 0.;
    for (int i = 0; i < n; i++)
    {
        semx = semx + exp(x[i] - mx);
    }
    return log(semx) + mx;
}

template<typename T>
T log_wishart_prior(int p, int k,
    Wishart wishart,
    const T* const sum_qs,
    const T* const Qdiags,
    const T* const icf)
{
    int n = p + wishart.m + 1;
    int icf_sz = p * (p + 1) / 2;

    double C = n * p * (log(wishart.gamma) - 0.5 * log(2)) - log_gamma_distrib(0.5 * n, p);

    T out = 0;
    for (int ik = 0; ik < k; ik++)
    {
        T frobenius = sqnorm(p, &Qdiags[ik * p]) + sqnorm(icf_sz - p, &icf[ik * icf_sz + p]);
        out = out + 0.5 * wishart.gamma * wishart.gamma * (frobenius)
            -wishart.m * sum_qs[ik];
    }

    return out - k * C;
}

template<typename T>
void preprocess_qs(int d, int k,
    const T* const icf,
    T* sum_qs,
    T* Qdiags)
{
    int icf_sz = d * (d + 1) / 2;
    for (int ik = 0; ik < k; ik++)
    {
        sum_qs[ik] = 0.;
        for (int id = 0; id < d; id++)
        {
            T q = icf[ik * icf_sz + id];
            sum_qs[ik] = sum_qs[ik] + q;
            Qdiags[ik * d + id] = exp(q);
        }
    }
}

template<typename T>
void Qtimesx(int d,
    const T* const Qdiag,
    const T* const ltri, // strictly lower triangular part
    const T* const x,
    T* out)
{
    for (int id = 0; id < d; id++)
        out[id] = Qdiag[id] * x[id];

    int Lparamsidx = 0;
    for (int i = 0; i < d; i++)
    {
        for (int j = i + 1; j < d; j++)
        {
            out[j] = out[j] + ltri[Lparamsidx] * x[i];
            Lparamsidx++;
        }
    }
}

template<typename T>
void gmm_objective(int d, int k, int n,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    const double* const x,
    Wishart wishart,
    T* err)
{
    const double CONSTANT = -n * d * 0.5 * log(2 * PI);
    int icf_sz = d * (d + 1) / 2;

    vector<T> Qdiags(d * k);
    vector<T> sum_qs(k);
    vector<T> xcentered(d);
    vector<T> Qxcentered(d);
    vector<T> main_term(k);

    preprocess_qs(d, k, icf, &sum_qs[0], &Qdiags[0]);

    T slse = 0.;
    for (int ix = 0; ix < n; ix++)
    {
        for (int ik = 0; ik < k; ik++)
        {
            subtract(d, &x[ix * d], &means[ik * d], &xcentered[0]);
            Qtimesx(d, &Qdiags[ik * d], &icf[ik * icf_sz + d], &xcentered[0], &Qxcentered[0]);

            main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5 * sqnorm(d, &Qxcentered[0]);
        }
        slse = slse + logsumexp(k, &main_term[0]);
    }

    T lse_alphas = logsumexp(k, alphas);

    *err = CONSTANT + slse - n * lse_alphas;

    *err = *err + log_wishart_prior(d, k, wishart, &sum_qs[0], &Qdiags[0], icf);
}

template<typename T>
void gmm_objective_split_inner(int d, int k,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    const double* const x,
    Wishart wishart,
    T* err)
{
    int icf_sz = d * (d + 1) / 2;

    T* Ldiag = new T[d];
    T* xcentered = new T[d];
    T* mahal = new T[d];
    T* lse = new T[k];

    for (int ik = 0; ik < k; ik++)
    {
        int icf_off = ik * icf_sz;
        T sumlog_Ldiag(0.);
        for (int id = 0; id < d; id++)
        {
            sumlog_Ldiag = sumlog_Ldiag + icf[icf_off + id];
            Ldiag[id] = exp(icf[icf_off + id]);
        }

        for (int id = 0; id < d; id++)
        {
            xcentered[id] = x[id] - means[ik * d + id];
            mahal[id] = Ldiag[id] * xcentered[id];
        }
        int Lparamsidx = d;
        for (int i = 0; i < d; i++)
        {
            for (int j = i + 1; j < d; j++)
            {
                mahal[j] = mahal[j] + icf[icf_off + Lparamsidx] * xcentered[i];
                Lparamsidx++;
            }
        }
        T sqsum_mahal(0.);
        for (int id = 0; id < d; id++)
        {
            sqsum_mahal = sqsum_mahal + mahal[id] * mahal[id];
        }

        lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5 * sqsum_mahal;
    }

    *err = logsumexp(k, lse);

    delete[] mahal;
    delete[] xcentered;
    delete[] Ldiag;
    delete[] lse;
}

template<typename T>
void gmm_objective_split_other(int d, int k, int n,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    Wishart wishart,
    T* err)
{
    const double CONSTANT = -n * d * 0.5 * log(2 * PI);

    T lse_alphas = logsumexp(k, alphas);

    T* sum_qs = new T[k];
    T* Qdiags = new T[d * k];
    preprocess_qs(d, k, icf, sum_qs, Qdiags);
    *err = CONSTANT - n * lse_alphas + log_wishart_prior(d, k, wishart, sum_qs, Qdiags, icf);
    delete[] sum_qs;
    delete[] Qdiags;
}