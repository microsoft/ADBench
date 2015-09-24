/*
 *  AU_MEX.H -- Simplify MEX file creation
 *
 * Mex files are a great way to speed up operations, but can be a 
 * little arcane to code.   This header file contains a number of routines 
 * to simplify them.
 *
 * The most important class is mlx_array<T> which behaves like a pointer to
 * an mxArray.  To write a fully error-checked mex file which adds two 
 * double arrays, write this:
 *
 *     #include "au_mex.h"
 *    
 *     // Declare mlx_function (C++ version of mexFunction)
 *     void mlx_function(mlx_inputs& in, mlx_outputs& out)
 *     {
 *        mlx_array<mlx_double> A(in[0]); // Get input 0
 *        mlx_array<mlx_double> B(in[1]); // Get input 1
 *       
 *        mlx_make_array<double> sum(A.size); // Make output array
 *       
 *        mlx_assert(A.size == B.size); // Check sizes are equal
 *       
 *        // Perform the operation
 *        for(mwSize i = 0; i < A.numel(); ++i)
 *          sum[i] = A[i] + B[i];
 *       
 *        out[0] = sum; // Assign to output
 *     }
 * 
 * */

#include <stdlib.h>
#include <math.h>
#include <string.h>

#include <mex.h>

// ----------------------------------------------------------------------------

// Assert macro.
// This is not disabled by optimization -- if you want to make an assert
// in a tight loop, wrap it in #ifdef MLX_DEBUG
#define mlx_assert(expr) if (expr) 0; else mexErrMsgTxt("mlx_assert failed: " #expr)


// ----------------------------------------------------------------------------

// Declare C types for matlab types, e.g. mlx_uint32 or mlx_single
// Declare mlx_class_id(T*), mapping from declared types, e.g. mlx_int32, or int32_T, to classid
#define DECLARE_MEX_CLASS(ID, matlab_type, ctype) \
  typedef ctype mlx_ ## matlab_type; \
  inline mxClassID mlx_class_id(mlx_ ## matlab_type *) { return ID; }\
  inline char const* mlx_class_name(mlx_ ## matlab_type *) { return # matlab_type; }
 
/* Declares:
typedef ... mlx_int8;  // mlx_int8 is the C++ type stored in a MATLAB int8
mxClassID mlx_class_id(mlx_int8*);  // Return mxINT8_CLASS
 */
DECLARE_MEX_CLASS(mxINT8_CLASS, int8, int8_T)
DECLARE_MEX_CLASS(mxUINT8_CLASS, uint8, uint8_T)
DECLARE_MEX_CLASS(mxINT16_CLASS, int16, int16_T)
DECLARE_MEX_CLASS(mxUINT16_CLASS, uint16, uint16_T)
DECLARE_MEX_CLASS(mxINT32_CLASS, int32, int32_T)
DECLARE_MEX_CLASS(mxUINT32_CLASS, uint32, uint32_T)
DECLARE_MEX_CLASS(mxINT64_CLASS, int64, int64_T)
DECLARE_MEX_CLASS(mxUINT64_CLASS, uint64, uint64_T)
DECLARE_MEX_CLASS(mxSINGLE_CLASS, single, float)
DECLARE_MEX_CLASS(mxDOUBLE_CLASS, double, double)
DECLARE_MEX_CLASS(mxLOGICAL_CLASS, logical, bool) // ????


// ---------------------------------------------------------------------------

/// Type query:
// if (mlx_isa<mlx_single>(a)) { /* .. it's single .. */ }
template <class T>
struct mlx_isa {
  bool it_is;
  mlx_isa(mxArray const* a) {
    it_is = (mxGetClassID(a) == mlx_class_id((T*)0));
  }
  operator bool () const { return it_is; }
};


// ----------------------------------------------------------------------------

// A struct to hold the matrix dimensions.
// This does not need to take ownership of the pointer,
// as it is guaranteed to stay alive as long as the matrix does.
struct mlx_dims {
  mwSize n;
  mwSize const *dims;
  
  mlx_dims():n(0), dims(0) {}
  mlx_dims(mwSize n_, mwSize const* dims_):n(n_), dims(dims_) {}
//  mlx_dims(int n_, int* dims_):n(n_), dims(dims_) {}
//  mlx_dims(size_t n_, size_t const* dims_):n(n_), dims(dims_) {}
  mlx_dims(const mlx_dims& that):n(that.n), dims(that.dims) {}
  
  // Range-checked access to dimensions
  mwSize operator[](int i) const { 
      mlx_assert(i >= 0);
      mlx_assert(i < n);
      return dims[i]; 
  }
};

struct mlx_size : public mlx_dims {
  mwSize data[2];
  mlx_size(mwSize rows, mwSize cols): mlx_dims(2, data) {
    data[0] = rows;
    data[1] = cols;
  }
};

// Check dims for equality
bool operator==(mlx_dims const& a, mlx_dims const& b)
{
    if (a.n != b.n) return false;
    for(int i = 0; i < a.n; ++i)
        if (a.dims[i] != b.dims[i])
            return false;
    
    return true;
}

// ----------------------------------------------------------------------------

// Pass to mlx_array to indicate that type mismatch is non-fatal.
static const bool mlx_array_nothrow = false;

// This is a (thankfully not too) smart pointer to an mxArray.
template <class T>
struct mlx_array {
  mxArray const* mx_array;
  mxClassID matlab_class_id;
  bool ok;
  T* data;
  mwSize rows;
  mwSize cols;
  mlx_dims size;
  mwSize numel_;
  
  // Take mxArray pointer 'a', and check that its contents
  // correspond to the template type parameter T.
  // If so, take local copies of its size and data pointer.
  mlx_array(mxArray const* a, bool throw_on_type_mismatch = true) 
  {
    mx_array = a;
    matlab_class_id = mlx_class_id((T*)0);
    ok = (a) && (mxGetClassID(a) == matlab_class_id);
    if (!ok) {
        if (throw_on_type_mismatch && a)
            mexErrMsgIdAndTxt("awful:bad_cast", "mlx_array<%s>: Bad cast from [%s]", mlx_class_name((T*)0), mxGetClassName(a));
        else
            return; // Return silently, caller can check flag;
    }
    
    // This is the correct type, set up the data
    data = (T*)mxGetData(a);
    rows = (mwSize)mxGetM(a);
    cols = (mwSize)mxGetN(a);
    size = mlx_dims(mxGetNumberOfDimensions(a), mxGetDimensions(a));

    if (size.n == 0)
       numel_ = 0;
      
    numel_ = size.dims[0];
    for(mwSize i = 1; i < size.n; ++i)
      numel_ *= size.dims[i];

    // We don't handle complex yet.
    if (mxGetPi(a) != 0)
        mexErrMsgIdAndTxt("awful:nocomplex", "mlx_array<T>: We don't handle complex yet");
  }
  
  // 1-based put
  void put1(mwIndex r, mwIndex c, const T& t) {
    data[r-1 + (c-1)*rows] = t;
  }
  // 1-based get
  T const& get1(mwIndex r, mwIndex c) const {
    return data[r-1 + (c-1)*rows];
  }

  // 0-based put
  void put0(mwIndex r, mwIndex c, const T& t) {
    data[r + c*rows] = t;
  }
  // 0-based get
  T const& get0(mwIndex r, mwIndex c) const {
    return data[r + c*rows];
  }
  
  // operator(int,int)
  T& operator()(mwIndex r, mwIndex c, ...) {
#ifndef AU_MEX_UNCHECKED
    mlx_assert(r >= 0 && r < rows);
    mlx_assert(c >= 0 && c < cols);
#endif
    return data[r + c*rows];
  }

  T const& operator()(mwIndex r, mwIndex c) const {
#ifndef AU_MEX_UNCHECKED
    mlx_assert(r >= 0 && r < rows);
    mlx_assert(c >= 0 && c < cols);
#endif
    return data[r + c*rows];
  }

  // 0-based []
  T const& operator[](mwIndex ind) const {
    mlx_assert(ind >= 0 && ind < numel_);
    return data[ind];
  }

  // 0-based []
  T & operator[](mwIndex ind) {
#ifndef AU_MEX_UNCHECKED
    mlx_assert(ind >= 0 && ind < numel_);
#endif
    return data[ind];
  }

  // Check if the type cast in the constructor succeeded.
  operator bool() const { return ok; }
  
  // Return number of elements
  mwSize numel() const {
      return numel_;
  }

};


// ----------------------------------------------------------------------------
// Create an mxArray of given size, with 
// the matlab class id corresponding to C++ type T
template <class T>
struct mlx_make_array : mlx_array<T>
{
    // Construct from (rows, cols)
    mlx_make_array(mwSize rows, mwSize cols):
        base_t(0)
    {
        mwSize dims[2] = {rows, cols};
        mlx_dims sz(2, dims);
        create(sz);
    }

    // Construct from size array
    mlx_make_array(mlx_dims const& sz):
        base_t(0)
    {
        create(sz);
    }

private:
    typedef mlx_array<T> base_t;
    
    void create(mlx_dims const& size_)
    {
        this->size = size_;
        int *odims = (int *)mxMalloc(sizeof(int)*this->size.n);
        this->numel_ = 1;
	for(int i=0; i<this->size.n; i++) {
            odims[i] = this->size.dims[i];
	    this->numel_ *= odims[i];
	}
        this->mx_array = mxCreateNumericArray(this->size.n, odims, 
                this->matlab_class_id, mxREAL);

        this->data = (T*)mxGetData(this->mx_array);
        this->rows = (mwSize)mxGetM(this->mx_array);
        this->cols = (mwSize)mxGetN(this->mx_array);
  }
};


// ----------------------------------------------------------------------------

// Class to collect input arguments, and apply error checking to their
// access.
struct mlx_inputs {
    int nrhs;
    mxArray const** prhs;
    
    // Construct from nrhs, prhs arguments to mexFunction
    mlx_inputs(int nrhs, mxArray const* prhs[]):nrhs(nrhs), prhs(prhs)
    {
    }
    
    mxArray const* operator[](int i) {
        mlx_assert(i >= 0);
        if (i >= nrhs)
            mexErrMsgIdAndTxt("awful:nin", "mlx_inputs: Expected at least %d input arguments", i+1);
        return prhs[i];
    }
};

// ----------------------------------------------------------------------------

// Helper class to allow
// out[i] = x;
// where x is an mlx_array<> object;
struct mlx_output {
    mxArray** array_ptr;
    
    // Construct from pointer to mxArray*
    mlx_output(mxArray** array_ptr = 0):array_ptr(array_ptr) {}
    
    // Assign from mlx_array<T>
    template <class T>
    mlx_output& operator=(mlx_array<T>& that) {
        *array_ptr = const_cast<mxArray*>(that.mx_array);
        return *this;
    }
    
    // Assign from mxArray*
    mlx_output& operator=(mxArray* that) {
        *array_ptr = that;
        return *this;
    }
};

// Class to collect output arguments, and apply error checking to their
// access.
struct mlx_outputs {
    int nlhs;
    mxArray** plhs;
    
    // Construct from nlhs, plhs arguments to mexFunction
    mlx_outputs(int nlhs, mxArray * plhs[]):nlhs(nlhs), plhs(plhs)
    {
    }
    // Access to ith output argument, with range checking
    // Special case i==0, as one may assign to that even if nlhs==0
    mlx_output operator[](int i)
    {
        mlx_assert(i >= 0);
        if (i > 0 && i >= nlhs)
            mexErrMsgIdAndTxt("awful:nout", "mlx_outputs: Expected at least %d output arguments", i+1);
        return mlx_output(&plhs[i]);
    }
};

#ifndef MLX_NO_MEXFUNCTION
void mlx_function(mlx_inputs& in, mlx_outputs& out);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   mlx_inputs  in(nrhs, prhs); // Wrap inputs -- allows us to check the number and datatypes
   mlx_outputs out(nlhs, plhs); // Wrap outputs
   mlx_function(in, out);
}
#endif
