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


// logsumexp of cols
template<typename T>
void logsumexp(const MatrixX<T>& X, ArrayX<T>& out);

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
    Map<const ArrayX<T>> const& alphas,
    Map<const MatrixX<T>> const& means,
    ArrayX<T> const& sum_qs,
    vector<MatrixX<T>> const& Qs,
    Map<const MatrixX<T>> const& x,
    Wishart wishart,
    T* err);

template<typename T>
void preprocess(int d, int k,
    const T* const icf,
    ArrayX<T>& sum_qs,
    vector<MatrixX<T>>& Qs);


////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////


// logsumexp of cols
template<typename T>
void logsumexp(const MatrixX<T>& X, ArrayX<T>& out)
{
    RowVectorX<T> mX = X.colwise().maxCoeff();
    RowVectorX<T> semX = (X.rowwise() - mX).array().exp().matrix().colwise().sum();
    out = semX.array().log() + mX.array();
}

template<typename T>
void gmm_objective_no_priors(int d, int k, int n,
    Map<const ArrayX<T>> const& alphas,
    Map<const MatrixX<T>> const& means,
    ArrayX<T> const& sum_qs,
    vector<MatrixX<T>> const& Qs,
    Map<const MatrixX<T>> const& x,
    Wishart wishart,
    T* err)
{
    MatrixX<T> Qxcentered(d, n), main_term(k, n);
    for (int ik = 0; ik < k; ik++)
    {
        Qxcentered.noalias() = Qs[ik] * (x.colwise() - means.col(ik));
        main_term.row(ik) = -0.5 * Qxcentered.colwise().squaredNorm();
    }
    main_term.colwise() += (alphas + sum_qs).matrix();
    ArrayX<T> slse;
    logsumexp(main_term, slse);

    T lse_alphas = logsumexp(alphas);
    double CONSTANT = -n * d * 0.5 * log(2 * PI);
    T tmp = slse.sum();
    *err = CONSTANT + slse.sum() - n * lse_alphas;
}

template<typename T>
void preprocess(int d, int k,
    const T* const icf,
    ArrayX<T>& sum_qs,
    vector<MatrixX<T>>& Qs)
{
    int icf_sz = d * (d + 1) / 2;

    sum_qs.resize(k);
    Qs.resize(k, MatrixX<T>::Zero(d, d));

    for (int ik = 0; ik < k; ik++)
    {
        int icf_off = ik * icf_sz;
        Map<const ArrayX<T>> q(&icf[icf_off], d);
        sum_qs[ik] = q.sum();
        int Lparamsidx = d;
        for (int i = 0; i < d; i++)
        {
            int n_curr_elems = d - i - 1;
            Qs[ik].col(i).bottomRows(n_curr_elems) =
                Map<const VectorX<T>>(&icf[icf_off + Lparamsidx], n_curr_elems);
            Lparamsidx += n_curr_elems;
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
    Map<const ArrayX<T>> map_alphas(alphas, k);
    Map<const MatrixX<T>> map_means(means, d, k);
    Map<const MatrixX<T>> map_x(x, d, n);

    ArrayX<T> sum_qs;
    vector<MatrixX<T>> Qs;
    preprocess(d, k, icf, sum_qs, Qs);

    gmm_objective_no_priors(d, k, n, map_alphas, map_means, sum_qs,
        Qs, map_x, wishart, err);
    *err += log_wishart_prior(d, k, wishart, sum_qs, Qs, icf);
}
