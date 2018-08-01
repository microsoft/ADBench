#include "au_mex.h"
#include "au_mex_visitor.h"

/*
%%  
 mex -Ic:/dev/codeplex/awful/matlab au_deep_vectorize_mex.cxx
 au_deep_vectorize_mex_test
%%

 */
struct CountingVisitor {
  size_t count;
  CountingVisitor(size_t count = 0): count(count) {
  }
  
  void VisitDoubles(double const* v, size_t n) {
    count += n;
  }
};

struct FillingVisitor {
  double* out_ptr;
  FillingVisitor(double* out_ptr): out_ptr(out_ptr) {
  }
  
  void VisitDoubles(double const* v, size_t n) {
    while (n--)
      *out_ptr++ = *v++;
  }
};

// Declare mlx_function (C++ version of mexFunction)
void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
  mxArray const* a = in[0];
  CountingVisitor visitor;
  au_visit_elements(a, &visitor);
  
  mlx_make_array<double> sum(mwSize(visitor.count),1); // Make output array
  au_visit_elements(a, &FillingVisitor(sum.data));
  
  out[0] = sum; // Assign to output
}
