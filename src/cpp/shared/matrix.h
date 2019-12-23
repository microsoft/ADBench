// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <cmath>

#include "defs.h"

////////////////////////////////////////////////////////////
//////////////////// Declarations //////////////////////////
////////////////////////////////////////////////////////////

// This throws error on n<1
template<typename T>
T arr_max(int n, const T* const x);
template<typename T>
int arr_max_idx(int n, const T* const x);

template<typename T>
T sqnorm(int n, const T* const x);

template<typename T>
void cross(
    const T* const a,
    const T* const b,
    T* out);

// out = a - b
template<typename T1, typename T2, typename T3>
void subtract(int d,
    const T1* const x,
    const T2* const y,
    T3* out);

// Multiplies n-dimensional vector x by a scalar factor
// Writes the result to n-dimensional vector out
template<typename T1, typename T2, typename T3>
void scale(int n, T1 factor, const T2* const x, T3* out);

// Multiplies n * m matrix x by m * p matrix y
// Writes result to n * p matrix out
// Matrices are stored column-major
template<typename T1, typename T2, typename T3>
void mat_mul(int n, int m, int p, const T1* const x, const T2* const y, T3* out);

// Adds n-dimensional vector x to n-dimensional vector acc
// Writes result to acc
template<typename T>
void add_to(int n, T* acc, const T* const x);

// Dot product of n-dimensional vectors x and y
// n must be greater or equal than 1
// n < 1 is UNDEFINED BEHAVIOR
template<typename T>
T dot(int n, const T* const x, const T* const y);

template<typename T>
void p2e(
    const T* const projective_coord,
    T* euclidean_coord);

////////////////////////////////////////////////////////////
//////////////////// Definitions ///////////////////////////
////////////////////////////////////////////////////////////

// inline so that it could be defined in the header
inline double log_gamma_distrib(double a, double p)
{
    double out = 0.25 * p * (p - 1) * log(PI);
    for (int j = 1; j <= p; j++)
    {
        out = out + lgamma(a + 0.5 * (1 - j));
    }
    return out;
}

// This throws error on n<1
template<typename T>
T arr_max(int n, const T* const x)
{
    T m = x[0];
    for (int i = 1; i < n; i++)
    {
#ifdef TOOL_ADEPT
        if (m < x[i])
            m = x[i];
#else
        m = fmax(m, x[i]);
#endif
    }
    return m;
}

template<typename T>
int arr_max_idx(int n, const T* const x)
{
    int max_idx = 0;
    for (int i = 1; i < n; i++)
    {
        if (x[max_idx] < x[i])
        {
            max_idx = i;
        }
    }
    return max_idx;
}

template<typename T>
T sqnorm(int n, const T* const x)
{
    T res = x[0] * x[0];
    for (int i = 1; i < n; i++)
        res = res + x[i] * x[i];
    return res;
}

template<typename T>
void cross(
    const T* const a,
    const T* const b,
    T* out)
{
    out[0] = a[1] * b[2] - a[2] * b[1];
    out[1] = a[2] * b[0] - a[0] * b[2];
    out[2] = a[0] * b[1] - a[1] * b[0];
}

// out = a - b
template<typename T1, typename T2, typename T3>
void subtract(int d,
    const T1* const x,
    const T2* const y,
    T3* out)
{
    for (int id = 0; id < d; id++)
    {
        out[id] = x[id] - y[id];
    }
}

template<typename T1, typename T2, typename T3>
void scale(int n, T1 factor, const T2* const x, T3* out)
{
    for (int i = 0; i < n; ++i)
        out[i] = factor * x[i];
}

template<typename T1, typename T2, typename T3>
void mat_mul(int n, int m, int p, const T1* const x, const T2* const y, T3* out)
{
    for (int i = 0; i < n; ++i)
    {
        for (int j = 0; j < p; ++j)
        {
            double rij = 0;
            for (int k = 0; k < m; ++k)
            {
                rij += x[k * n + i] * y[j * m + k];
            }
            out[j * n + i] = rij;
        }
    }
}

template<typename T>
void add_to(int n, T* acc, const T* const x)
{
    for (int i = 0; i < n; ++i)
        acc[i] += x[i];
}

template<typename T>
T dot(int n, const T* const x, const T* const y)
{
    T acc = x[0] * y[0];
    for (int i = 1; i < n; ++i)
        acc += x[i] * y[i];

    return acc;
}

template<typename T>
void p2e(
    const T* const projective_coord,
    T* euclidean_coord)
{
    euclidean_coord[0] = projective_coord[0] / projective_coord[2];
    euclidean_coord[1] = projective_coord[1] / projective_coord[2];
}