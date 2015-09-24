#include "au_mex.h"
#include "au_mex_visitor.h"

/*
%%  
 mex -Ic:/dev/codeplex/awful/matlab au_deep_vectorize_mex.cxx
 au_deep_vectorize_mex_test
%%
 */

struct WritingVisitor {
  double const* in_ptr;
  double const* in_end;
  WritingVisitor(double const* in_ptr, double const* in_end):
    in_ptr(in_ptr),
    in_end(in_end)
  {
  }
  
  void VisitDoubles(double const* v, size_t n) {
    auto vp = const_cast<double*>(v);
    while (n--) {
      if (in_ptr == in_end)
	mexErrMsgIdAndTxt("au_deep_unvectorize_mex:TooSmall", "Too few entries in rhs");
      *vp++ = *in_ptr++;
    }
  }
};

// Declare mlx_function (C++ version of mexFunction)
void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
  mlx_array<double> a = in[1];

  mxArray* tpl_writeable = mxDuplicateArray(in[0]);
  
  WritingVisitor visitor(a.data, a.data+a.numel());
  au_visit_elements(tpl_writeable, &visitor);

  out[0] = tpl_writeable;
}
