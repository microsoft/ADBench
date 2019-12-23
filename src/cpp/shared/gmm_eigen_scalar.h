// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <cmath>
#include <vector>
#include "defs.h"
#include "matrix.h"

#include "Eigen/Dense"

#include "gmm_eigen.h"

using std::vector;

using Eigen::Map;
template<typename T>
using VectorX = Eigen::Matrix<T, -1, 1>;
template<typename T>
using RowVectorX = Eigen::Matrix<T, 1, -1>;
template<typename T>
using MatrixX = Eigen::Matrix<T, -1, -1>;
template<typename T>
using ArrayX = Eigen::Array<T, -1, 1>;

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////


template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
    const Map<const ArrayX<T>>& alphas,
    const vector<Map<const VectorX<T>>>& mus,
    const ArrayX<T>& sum_qs,
    const vector<MatrixX<T>>& Qs,
    const double* const x,
    Wishart wishart,
    T* err);


template<typename T>
void preprocess(int d, int k,
    const T* const means,
    const T* const icf,
    vector<Map<const VectorX<T>>>& mus,
    ArrayX<T>& sum_qs,
    vector<MatrixX<T>>& Qs);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////


template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
    const Map<const ArrayX<T>>& alphas,
    const vector<Map<const VectorX<T>>>& mus,
    const ArrayX<T>& sum_qs,
    const vector<MatrixX<T>>& Qs,
    const double* const x,
    Wishart wishart,
    T* err)
{
    VectorX<T> xcentered(d), Qxcentered(d);
    ArrayX<T> lse(k);
    T slse = 0.;
    for (int ix = 0; ix < n; ix++)
    {
        Map<const VectorX<T>> curr_x(&x[ix * d], d);
        for (int ik = 0; ik < k; ik++)
        {
            switch (3) // 3 is the fastest, (and 2 is slightly faster than 4)
            {
            case 2:
                xcentered = curr_x - mus[ik];
                Qxcentered.noalias() = Qs[ik].template triangularView<Eigen::Lower>() * xcentered;
                lse(ik) = -0.5 * Qxcentered.squaredNorm();
                break;
            case 3:
                xcentered = curr_x - mus[ik];
                Qxcentered.noalias() = Qs[ik] * xcentered;
                lse(ik) = -0.5 * Qxcentered.squaredNorm();
                break;
            case 4:
                lse(ik) = -0.5 * (Qs[ik].template triangularView<Eigen::Lower>() * (curr_x - mus[ik])).squaredNorm();
                break;
            }
        }
        lse = lse + alphas + sum_qs;
        slse = slse + logsumexp(lse);
    }

    T lse_alphas = logsumexp(alphas);
    double CONSTANT = -n * d * 0.5 * log(2 * PI);

    *err = CONSTANT + slse - n * lse_alphas;
}

template<typename T>
void preprocess(int d, int k,
    const T* const means,
    const T* const icf,
    vector<Map<const VectorX<T>>>& mus,
    ArrayX<T>& sum_qs,
    vector<MatrixX<T>>& Qs)
{
    int icf_sz = d * (d + 1) / 2;

    sum_qs.resize(k);
    Qs.resize(k, MatrixX<T>::Zero(d, d));

    for (int ik = 0; ik < k; ik++)
    {
        int icf_off = ik * icf_sz;
        mus.emplace_back(&means[ik * d], d);
        Map<const ArrayX<T>> q(&icf[icf_off], d);
        sum_qs[ik] = q.sum();
        int Lparamsidx = d;
        for (int i = 0; i < d; i++)
        {
            int n_curr_elems = d - i - 1;
            Qs[ik].col(i).bottomRows(n_curr_elems) =
                Map<const VectorX<T>>(&icf[icf_off + Lparamsidx], n_curr_elems);
            Lparamsidx = Lparamsidx + n_curr_elems;
        }
        Qs[ik].diagonal() = q.exp();
    }
}

template<typename T>
void gmm_objective(int d, int k, int n,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    const T* const x,
    Wishart wishart,
    T* err)
{
    int icf_sz = d * (d + 1) / 2;

    // init eigen wrappers first
    vector<Map<const VectorX<T>>> mus;
    ArrayX<T> sum_qs;
    vector<MatrixX<T>> Qs;
    preprocess(d, k, means, icf, mus, sum_qs, Qs);

    Map<const ArrayX<T>> map_alphas(alphas, k);
    gmm_objective_no_priors(d, k, n, map_alphas, mus, sum_qs,
        Qs, x, wishart, err);
    *err = *err + log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);
}
