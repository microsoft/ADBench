// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <cmath>
#include <vector>
#include "defs.h"
#include "matrix.h"

#include "Eigen/Dense"

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

// d: dim
// k: number of gaussians
// n: number of points
// alphas: k logs of mixture weights (unnormalized), so
//            weights = exp(log_alphas) / sum(exp(log_alphas))
// means: d*k component means
// icf: (d*(d+1)/2)*k inverse covariance factors 
//                    every icf entry stores firstly log of diagonal and then 
//          columnwise other entris
//          To generate icf in MATLAB given covariance C :
//              L = inv(chol(C, 'lower'));
//              inv_cov_factor = [log(diag(L)); L(au_tril_indices(d, -1))]
// wishart: wishart distribution parameters
// x: d*n points
// err: 1 output
template<typename T>
void gmm_objective(int d, int k, int n,
    const T* const alphas,
    const T* const means,
    const T* const icf,
    const T* const x,
    Wishart wishart,
    T* err);

template<typename T>
double logsumexp(const ArrayX<T>& x);

// p: dim
// k: number of components
// wishart parameters
// sum_qs: sum of log diags of Qs
// Qs: icf composed into matrices
// icf: (p*(p+1)/2)*k inverse covariance factors
template<typename T>
double log_wishart_prior(int p, int k,
    Wishart wishart,
    const ArrayX<T>& sum_qs,
    const vector<MatrixX<T>>& Qs,
    const T* const icf);


////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////


template<typename T>
T logsumexp(const ArrayX<T>& x)
{
    T mx = x.maxCoeff();
    T semx = (x.array() - mx).exp().sum();
    return log(semx) + mx;
}

template<typename T>
double log_wishart_prior(int p, int k,
    Wishart wishart,
    const ArrayX<T>& sum_qs,
    const vector<MatrixX<T>>& Qs,
    const T* const icf)
{
    int n = p + wishart.m + 1;
    int icf_sz = p * (p + 1) / 2;

    double C = n * p * (log(wishart.gamma) - 0.5 * log(2.)) - log_gamma_distrib(0.5 * n, p);

    double sum_frob = 0;
    for (int ik = 0; ik < k; ik++)
    {
        Map<const VectorX<T>> L(&icf[icf_sz * ik + p], icf_sz - p);
        sum_frob = sum_frob + L.squaredNorm() + Qs[ik].diagonal().squaredNorm();
    }

    return 0.5 * wishart.gamma * wishart.gamma * sum_frob - wishart.m * sum_qs.sum() - k * C;
}
