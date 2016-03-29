#include "au_mex.h"

// Declare mlx_function (C++ version of mexFunction)
// Compare to 
// https://awful.codeplex.com/SourceControl/latest#matlab/au_mex_example_1.cxx 
void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
   mlx_array<mlx_double> A(in[0]); // Get input 0
   mlx_array<mlx_double> B(in[1]); // Get input 1

   mlx_make_array<double> sum(A.size); // Make output array

   mlx_assert(A.size == B.size); // Check sizes are equal
   
   // Perform the operation
   for(mwSize i = 0; i < A.numel(); ++i)
     sum[i] = A[i] + B[i];

   out[0] = sum; // Assign to output
}
