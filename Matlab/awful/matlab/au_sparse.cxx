/*==============================================================
* awf_sparse.cxx
*   Faster sparse()  See au_sparse.m for more help.
*
* This is a MEX-file for MATLAB.  
* Copyright (c) 1984-2000 The MathWorks, Inc.
* 
*=============================================================*/
/* $ Revision: 1.5 $ */
#include <math.h> /* Needed for the ceil() prototype. */
#include "au_mex.h"

#define AWFDEBUG 0

#if AWFDEBUG
#define AASSERT(e) if (e) 1; else { printf("awf_sparse: ASSERTION FAILURE, line %d [" #e "]", __LINE__); mexErrMsgTxt("ASSERT FAIL"); }
#else
#define AASSERT(e)
#endif

#define APRINTF if (!AWFDEBUG) 1; else mexPrintf 

void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
  mlx_array<mlx_int32> pi(in[0]);
  mlx_array<mlx_int32> pj(in[1]);
  mlx_array<mlx_double> pv(in[2]);
  
  /* Get the size and pointers to input data. */
  mlx_assert(pi.rows * pi.cols == pj.rows * pj.cols);
  mlx_assert(pv.rows * pv.cols == pj.rows * pj.cols);
  
  mwSize n = pi.rows * pi.cols;

  // Find row/col size
  mlx_int32 rows = 0;
  mlx_int32 cols = 0;
  if (in.nrhs == 5) {
      rows = mlx_array<mlx_double>(in[3]).get0(0,0);
      cols = mlx_array<mlx_double>(in[4]).get0(0,0);
  } else {
      // Find maxima
      for(mwIndex i = 0; i < n; ++i) {
          if (pi[i] > rows) rows = pi[i];
          if (pj[i] > cols) cols = pj[i];
      }
  }
  
  APRINTF("awf_sparse: size = [%d %d]\n", rows, cols);

  // Error check, and count number of nonzeros
  mwIndex nzmax = 0;
  mwIndex last_r = 0;
  mwIndex last_c = 0;
  for(mwIndex i = 0; i < n; ++i) {
    mlx_int32 r = pi[i];
    mlx_int32 c = pj[i];
    bool this_nz = (pv[i] != 0.0);
    if (r < 1 || r > rows) {
      mexErrMsgTxt("awf_sparse: r out of range");
    }
    if (c < 1 || c > cols) {
      mexErrMsgTxt("awf_sparse: c out of range");
    }
    APRINTF("add (%d, %d) : %g\n", r,c, pv[i]);
    if (i > 0 && c < last_c)
      mexErrMsgTxt("awf_sparse: cols must be monotonic");
    if (i > 0 && c == last_c) {
      if (r < last_r)
	mexErrMsgTxt("awf_sparse: rows must be monotonic within columns");
      if (r != last_r)
	if (this_nz) ++nzmax;
    } else {
      if (this_nz) ++nzmax;
    }
    last_c = c;
    last_r = r;
  }

  if (nzmax > double(rows)*cols) {
    printf("awf_sparse: size %dx%d nzmax %d\n", rows, cols, nzmax);
    mexErrMsgTxt("awf_sparse: documentation requires nzmax < rows*cols");
  }
  
  mxArray* sout = mxCreateSparse(rows,cols,nzmax,mxREAL);
  mlx_double* sv  = mxGetPr(sout); // sparse values, so S(*ir, *jr) = *sv;
  mwIndex* ir = mxGetIr(sout);  // row indices -- must be increasing colwise
  mwIndex* jc = mxGetJc(sout);  // Column info -- size == cols+1

  APRINTF("awf_sparse: size %dx%d nzmax %d\n", rows, cols, nzmax);
  
  out[0] = sout;
  
  if (nzmax == 0)
    return;

  last_r = -1;
  last_c = pj[0];
  for(int k=0; k < last_c; ++k)
    jc[k] = 0;
  int nz_index = 0;
  for(int i = 0; i < n; ++i) {
    mlx_int32 r = pi[i];
    mlx_int32 c = pj[i];
    double v = pv[i];
    bool this_nz = (v != 0.0);
    APRINTF("awf_sparse: s(%d,%d) += %g ", r,c,v);

    if (!this_nz) {
      APRINTF("zero\n");
      continue;
    }
    
    if (c == last_c && r == last_r) {
      // just increment value of previous
      if (nz_index < 1) mexErrMsgTxt("awf_sparse: internal error");
      AASSERT(nz_index-1 < nzmax);
      sv[nz_index-1] += v;
      APRINTF("augmented %d\n", nz_index-1);
    } else {
      // Add a new element
      AASSERT(nz_index < nzmax);
      ir[nz_index] = r-1;
      sv[nz_index] = v;
      // Increment column info if moving to new col
      if (c > last_c) {
	for(mwIndex k = last_c; k < c; ++k) {
	  AASSERT(k < cols);
	  jc[k] = nz_index;
	}
      }
      APRINTF("filled %d\n", nz_index);
      ++nz_index;
    }
    
    last_c = c;
    last_r = r;
  }
  
  if (nz_index != nzmax) {
    APRINTF("awf_sparse: ERROR: nz_index = %d != nzmax = %d\n", nz_index, nzmax);
    mexErrMsgTxt("zzzoiks");
  }
  
  if (last_c < cols) {
    for(int k = last_c; k <= cols; ++k)
      jc[k] = nz_index;
  }
  jc[cols] = nz_index;
  //  for(k = 0; k <= cols; ++k) printf("%5d\n", jc[k]);
}
