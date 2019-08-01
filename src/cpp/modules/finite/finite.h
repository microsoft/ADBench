#pragma once

#include <vector>
#include <functional>

const double DEFAULT_DELTA = 1e-7;

// VECTOR UTILS

// Subtract B from A
template<typename T>
T* sub_vec(T* a, const T* b, int sz) {
    for (int i = 0; i < sz; i++) a[i] -= b[i];
    return a;
}

// Divide vector A by scalar B
template<typename T>
T* div_vec(T* a, int a_sz, T b) {
    for (int i = 0; i < a_sz; i++) a[i] /= b;
    return a;
}

// Insert B starting at a point in A
template<typename T>
T* vec_ins(T* a, const T* b, int b_sz) {
    for (int i = 0; i < b_sz; i++) a[i] = b[i];
    return a;
}

// FINITE DIFFERENTIATION FUNCTION

/// <summary>Approximately differentiate a function using finite differences</summary>
/// <param name="func">Function to be differentiated.
///		Should accept 2 pointers as arguments (one input, one output).
///		Each output will be differentiated with respect to each input.</param>
/// <param name="input">Pointer to input data (scalar or vector)</param>
/// <param name="input_size">Input data size (1 for scalar)</param>
/// <param name="output">Pointer to where 'func' should output data (scalar or vector)</param>
/// <param name="output_size">Size of 'func' output data</param>
/// <param name="result">Pointer to where resultant Jacobian should go.
///		Will be stored as a vector(input_size * output_size).
///		Will store in format foreach (input) { foreach (output) {} }</param>
/// <param name="delta">The difference to use in finite differentiation</param>
template<typename T>
void finite_differences(std::function<void(T*, T*)> func,
    T* input, int input_size, T* output, int output_size,
    T* result, T delta = DEFAULT_DELTA)
{
    func(input, output);
    std::vector<T> tmp_output(output_size);
    for (int i = 0; i < input_size; i++)
    {
        input[i] += delta;
        func(input, tmp_output.data());
        div_vec(sub_vec(tmp_output.data(), output, output_size), output_size, delta);
        vec_ins(&result[output_size * i], tmp_output.data(), output_size);
        input[i] -= delta;
    }
}

/// <summary>Approximately differentiate a function using finite differences.
///     This variation expects 'func(input)' to be pre-computed.
///     It can be used to continuously, part-by-part compute the gradient of one function.</summary>
/// <param name="func">Function to be differentiated.
///		Should accept 2 pointers as arguments (one input, one output).
///		Each output will be differentiated with respect to each input.</param>
/// <param name="input">Pointer to input data (scalar or vector)</param>
/// <param name="input_size">Input data size (1 for scalar)</param>
/// <param name="output">Pointer to pre-computed 'func(input)'s output data (scalar or vector)</param>
/// <param name="output_size">Size of 'func' output data</param>
/// <param name="result">Pointer to where resultant Jacobian should go.
///		Will be stored as a vector(input_size * output_size).
///		Will store in format foreach (input) { foreach (output) {} }</param>
/// <param name="delta">The difference to use in finite differentiation</param>
template<typename T>
void finite_differences_continue(std::function<void(T*, T*)> func,
    T* input, int input_size, const T* output, int output_size,
    T* result, T delta = DEFAULT_DELTA)
{
    std::vector<T> tmp_output(output_size);
    for (int i = 0; i < input_size; i++)
    {
        input[i] += delta;
        func(input, tmp_output.data());
        div_vec(sub_vec(tmp_output.data(), output, output_size), output_size, delta);
        vec_ins(&result[output_size * i], tmp_output.data(), output_size);
        input[i] -= delta;
    }
}