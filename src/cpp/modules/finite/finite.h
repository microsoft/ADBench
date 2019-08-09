#pragma once

#include <vector>
#include <functional>
#include <algorithm>

const double FINITE_DIFFERENCES_DEFAULT_EPSILON = std::sqrt(std::numeric_limits<double>::epsilon());
const double FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_RADIUS = 1;
const double FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_CHARACTERISTIC_SCALE = 1;

// Engine for arrpoximate differentiation using finite differences.
// Shares temporary memory buffer between calls.
template<typename T>
class FiniteDifferencesEngine
{
private:
    std::vector<T> tmp_output;
    int max_output_size;

    // VECTOR UTILS

    // Subtract B from A
    static T* sub_vec(T* a, const T* b, int sz) {
        for (int i = 0; i < sz; ++i)
            a[i] -= b[i];
        return a;
    }

    // Divide vector A by scalar B
    static T* div_vec(T* a, int a_sz, T b) {
        for (int i = 0; i < a_sz; ++i)
            a[i] /= b;
        return a;
    }

    // Insert B starting at a point in A
    static T* vec_ins(T* a, const T* b, int b_sz) {
        for (int i = 0; i < b_sz; ++i)
            a[i] = b[i];
        return a;
    }

public:
    // max_output_size - maximum size of the ouputs of the functions
    // this engine will be able to approximately differentiate
    FiniteDifferencesEngine(int max_output_size): max_output_size(max_output_size), tmp_output(max_output_size)
    {}

    FiniteDifferencesEngine() : max_output_size(0), tmp_output(0)
    {}

    // sets max_output_size - maximum size of the ouputs of the functions
    // this engine is be able to approximately differentiate
    void set_max_output_size(int size)
    {
        tmp_output.resize(size);
        max_output_size = size;
    }

    // gets max_output_size - maximum size of the ouputs of the functions
    // this engine is be able to approximately differentiate
    int current_max_output_size()
    {
        return max_output_size;
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
    /// <param name="epsilon">Coefficient by which the value of the input variable is multiplied
    ///     to determine the difference to use in finite differentiation when the absolute value
    ///     of the said variable is greater or equal to zero_neighborhood_radius</param>
    /// <param name="zero_neighborhood_radius">Radius of the neighborhood of zero where the difference
    ///     used in finite differentiation should not be proportional to the input</param>
    /// <param name="zero_neighborhood_characteristic_scale">Value, which when multiplied by epsilon
    ///     gives the difference to use in finite differentiation when the absolute value
    ///     of the said variable is lesser than zero_neighborhood_radius</param>
    void finite_differences(std::function<void(T*, T*)> func,
        T* input, int input_size, T* output, int output_size,
        T* result, T epsilon = FINITE_DIFFERENCES_DEFAULT_EPSILON,
        T zero_neighborhood_radius = FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_RADIUS,
        T zero_neighborhood_characteristic_scale = FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_CHARACTERISTIC_SCALE)
    {
        func(input, output);
        finite_differences_continue(func, input, input_size, output, output_size, result, epsilon, zero_neighborhood_radius, zero_neighborhood_characteristic_scale);
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
    /// <param name="epsilon">Coefficient by which the value of the input variable is multiplied
    ///     to determine the difference to use in finite differentiation when the absolute value
    ///     of the said variable is greater or equal to zero_neighborhood_radius</param>
    /// <param name="zero_neighborhood_radius">Radius of the neighborhood of zero where the difference
    ///     used in finite differentiation should not be proportional to the input</param>
    /// <param name="zero_neighborhood_characteristic_scale">Value, which when multiplied by epsilon
    ///     gives the difference to use in finite differentiation when the absolute value
    ///     of the said variable is lesser than zero_neighborhood_radius</param>
    void finite_differences_continue(std::function<void(T*, T*)> func,
        T* input, int input_size, const T* output, int output_size,
        T* result, T epsilon = FINITE_DIFFERENCES_DEFAULT_EPSILON,
        T zero_neighborhood_radius = FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_RADIUS,
        T zero_neighborhood_characteristic_scale = FINITE_DIFFERENCES_DEFAULT_ZERO_NEIGHBORHOOD_CHARACTERISTIC_SCALE)
    {
        volatile T tmp;
        for (int i = 0; i < input_size; i++)
        {
            T originalInput = input[i];
            T absInput = std::abs(originalInput);
            T delta = absInput >= zero_neighborhood_radius ? absInput * epsilon : zero_neighborhood_characteristic_scale * epsilon;
            // adjusting delta so that (input[i] + delta) - input[i] == delta
            tmp = originalInput + delta;
            delta = tmp - originalInput;

            input[i] += delta;
            func(input, tmp_output.data());
            div_vec(sub_vec(tmp_output.data(), output, output_size), output_size, delta);
            vec_ins(&result[output_size * i], tmp_output.data(), output_size);
            input[i] = originalInput;
        }
    }
};