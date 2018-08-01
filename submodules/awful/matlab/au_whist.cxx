#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
   if (nrhs != 3)
      mexErrMsgTxt("awf_whist: must have 3 arguments");

   if (!mxIsDouble(prhs[0]))
     mexErrMsgTxt("awf_whist: takes only double arguments for I");
   if (!mxIsDouble(prhs[1]))
     mexErrMsgTxt("awf_whist: takes only double arguments for W");
   
   if (nlhs != 1)
     mexErrMsgTxt("Must have exactly one output.");

   mxArray const* i_mx = prhs[0];
   mxArray const* w_mx = prhs[1];
   mxArray const* imax_mx = prhs[2];

   int r = mxGetM(i_mx);
   int c = mxGetN(i_mx);
   int l = (r > c) ? r : c;
   if (!((r > c) ? (c == 1) : (r == 1)))
     mexErrMsgTxt("awf_whist: min(size(i)) should be 1");
   double const* i = mxGetPr(i_mx);
   
   int rw = mxGetM(w_mx);
   int cw = mxGetN(w_mx);
   int lw = (rw > cw) ? rw : cw;
   if (!((rw > cw) ? (cw == 1) : (rw == 1)))
     mexErrMsgTxt("awf_whist: min(size(w)) should be 1");
   double const* w = mxGetPr(w_mx);

   if (!(mxGetN(imax_mx) == 1) && (mxGetM(imax_mx) == 1))
     mexErrMsgTxt("awf_whist: size(imax) should be [1 1]");
   int imax = (int)*mxGetPr(imax_mx);
   if (imax < 1)
     mexErrMsgTxt("awf_whist: imax < 1");

   // Further sanity checks
   if (lw != l)
     mexErrMsgTxt("awf_whist: length(i) should = length(w)");
   
   // make output array
   plhs[0] = mxCreateDoubleMatrix(1, imax, mxREAL);
   double* out = mxGetPr(plhs[0]);
   for(int j = 0; j < imax; ++j)
     out[j] = 0;
   
   for(int j = 0; j < l; ++j, ++i, ++w) {
     int loc = int(*i)-1;
     if (loc < 0 || loc >= imax)
       mexErrMsgTxt("awf_whist: an element of i is > imax");
     out[loc] += *w;
   }
}
