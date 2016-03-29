
// au_mex_example_2
// Shows how to specialize for different types.

#include "au_mex.h"

template <class Real>
mlx_array<Real> Compute(mlx_array<Real> const& A, mlx_array<Real> const& B)
{
   mlx_assert(A.size == B.size);// Check sizes match
   
   mlx_make_array<Real> sum(A.size); // Make output array

   // Perform the operation
   for(int i = 0; i < A.numel(); ++i)
     sum[i] = A[i] + B[i];

   return sum;
}

template <class Real>
bool try_cast(mxArray const* pA, mxArray const* pB, mlx_output* out)
{
   if (!(mlx_isa<Real>(pA) && mlx_isa<Real>(pB))) 
      return false;  // Return silently if types don't match.

   mlx_array<Real> A(pA);  
   mlx_array<Real> B(pB);

   *out = Compute(A, B);
   return true;
}

void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
   // Enumerate the types.  You really do have to do this, so that the 
   // C++ compiler can lay down different code for each case.
   // You could clean this up with a macro if you like that sort of thing.
   if (try_cast<mlx_double>(in[0], in[1], &out[0])) return;
   if (try_cast<mlx_single>(in[0], in[1], &out[0])) return;
   if (try_cast<mlx_uint8>(in[0], in[1], &out[0])) return;
 
   mexErrMsgIdAndTxt("awful:types", "We don't handle this input type combo: %s, %s", 
           mxGetClassName(in[0]), mxGetClassName(in[1]));
}
