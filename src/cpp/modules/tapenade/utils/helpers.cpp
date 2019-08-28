#include "helpers.h"

// Initializes array with zeros.
void init_zeros(double* arr, int size)
{
    int i;

    for (i = 0; i < size; i++)
    {
        arr[i] = 0.0;
    }
}

// Allocates and initializes double array with zeros.
double* get_zero_array(int size)
{
    double* arr = (double*)malloc(size * sizeof(double));
    init_zeros(arr, size);
    return arr;
}