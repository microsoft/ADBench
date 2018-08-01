#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
        mexErrMsgIdAndTxt("awful:mexeg", "Expected 2 inputs");
    
    // Get input 0
    mxArray const* A = prhs[0];
    if (!mxIsDouble(A) || mxIsComplex(A))
        mexErrMsgIdAndTxt("awful:mexeg", "Expected double arrays");

    // Get input 1
    mxArray const* B = prhs[1];
    if (!mxIsDouble(A) || mxIsComplex(B))
        mexErrMsgIdAndTxt("awful:mexeg", "Expected double arrays");

    mwSize m = mxGetM(A);
    mwSize n = mxGetN(A);

    if (mxGetM(A) != mxGetM(B) || mxGetN(A) != mxGetN(B))
        mexErrMsgIdAndTxt("awful:mexeg", "Same sizes");
            
    // Make output array
    if (nlhs != 1)
        mexErrMsgIdAndTxt("awful:mexeg", "Expected 1 output");

    plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
    double* Aptr = mxGetPr(A);
    double* Bptr = mxGetPr(B);
    double* optr = mxGetPr(plhs[0]);
    
    // Perform the operation
    for(size_t i = 0; i < m*n; ++i)
        optr[i] = Aptr[i] + Bptr[i];
}
