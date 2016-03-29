/* adept.h -- Header for fast automatic differentiation using expression templates

    Copyright (C) 2012-2015 The University of Reading

    Author: Robin Hogan <r.j.hogan@reading.ac.uk>

    This file is part of the Adept library.


   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#ifndef ADEPT_H
#define ADEPT_H 1

/* Contents:
   SECTION 0: Adept version
   SECTION 1: User changable defines
   SECTION 2: Defines requiring a library recompile 
   SECTION 3: Header files
   SECTION 4: Miscellaneous
   SECTION 5: Exceptions
   SECTION 6: Definition of Stack class
   SECTION 7: Definition of Expression types
   SECTION 8: Definition of Traits
   SECTION 9: Definition of aReal
   SECTION 10: Helper functions
*/

// ---------------------------------------------------------------------
// SECTION 0: Version
// ---------------------------------------------------------------------

// The version of the Adept library is specified both as a string and
// an integer, where the string is of the form major.minor.revision,
// and .revision is omitted if it is zero.
#define ADEPT_VERSION      10100
#define ADEPT_VERSION_STR "1.1"


// ---------------------------------------------------------------------
// SECTION 1: User changable defines
// ---------------------------------------------------------------------

// The following can either be changed here, or define them just
// before including this header file in your code, or define using the
// -Dxxx compiler option.  These options to not need the library to be
// recompiled.

// A globally accessible stack needs to be present for arithmetic
// statements to access; by default this is thread safe but if you
// know you are running a single-threaded application then slightly
// faster performance may be achieved by defining this. Note that in
// section 4 of this header file, ADEPT_STACK_THREAD_UNSAFE is
// explicitly defined on the Mac OS platform, since the executable
// format used typically does not support thread-local storage.
//#define ADEPT_STACK_THREAD_UNSAFE 1

// Define this to check whether the "multiplier" is zero before it is
// placed on the operation stack. This makes the forward pass slower
// and the reverse pass slightly faster, and is only worthwhile if
// many reverse passes will be carried out per forward pass (or if you
// have good reason to believe many variables in your code are zero).
// #define ADEPT_REMOVE_NULL_STATEMENTS 1

// If copy constructors for aReal objects are only used in the return
// values for functions then defining this will lead to slightly
// faster code, because it will be assumed that when a copy
// constructor is called the gradient_offset can simply be copied
// because the object being copied will shortly be destructed. You
// need to be sure that the code does not contain these constructions:
//   aReal x = y;
//   aReal x(y);
// where y is an aReal object.
//#define ADEPT_COPY_CONSTRUCTOR_ONLY_ON_RETURN_FROM_FUNCTION 1

// If using the same code for both forward-only and
// forward-and-reverse calculations, then it is useful to be able to
// dynamically control whether or not gradient information is computed
// by expressions in the forward pass using the pause_recording() and
// continue_recording() functions. To enable this feature uncomment
// the following, but note that it slows down the forward pass a
// little.  
//#define ADEPT_RECORDING_PAUSABLE 1

// Often when you first convert a code for automatic differentiation
// the gradients computed contain NaNs or infinities: uncommenting the
// following will check for these and throw an error when they are
// found, so that by running the program in a debugger and looking at
// the backtrace, you can locate the source.
//#define ADEPT_TRACK_NON_FINITE_GRADIENTS 1

// If this is defined then each mathematical operation does not
// involve a check whether more memory needs to be allocated; rather
// the user first specifies how much memory to allocate to hold the
// entire algorithm via the preallocate_statements and
// preallocate_operations functions. This is a little faster, but is
// obviously risky if you don't anticipate correctly how much memory
// will be needed.
//#define ADEPT_MANUAL_MEMORY_ALLOCATION 1

// The initial size of the stacks, which can be grown if required
#ifndef ADEPT_INITIAL_STACK_LENGTH
#define ADEPT_INITIAL_STACK_LENGTH 1000
#endif


// ---------------------------------------------------------------------
// SECTION 2: Defines requiring a library recompile
// ---------------------------------------------------------------------

// The "stack" containing derivative information can be implemented in
// two ways: if ADEPT_STACK_STORAGE_STL is defined then C++ STL
// containers are used, otherwise dynamically allocated arrays are
// used.  Experience says that dynamically allocated arrays are faster.
//#define ADEPT_STACK_STORAGE_STL 1

// The number of rows/columns of a Jacobian that are calculated at
// once. The optimum value depends on platform, the size of your
// Jacobian and the number of OpenMP threads available.
#ifndef ADEPT_MULTIPASS_SIZE
//#define ADEPT_MULTIPASS_SIZE 1
//#define ADEPT_MULTIPASS_SIZE 2
#define ADEPT_MULTIPASS_SIZE 4
//#define ADEPT_MULTIPASS_SIZE 8
//#define ADEPT_MULTIPASS_SIZE 15
//#define ADEPT_MULTIPASS_SIZE 16
//#define ADEPT_MULTIPASS_SIZE 32
//#define ADEPT_MULTIPASS_SIZE 64
#endif

// If ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK then the
// Jacobian calculation will try to remove redundant loops involving
// zeros; note that this may inhibit auto-vectorization
#define ADEPT_MULTIPASS_SIZE_ZERO_CHECK 64

// By default the precision of differentiated expressions is "double".
// To override this, define ADEPT_FLOATING_POINT_TYPE to the type
// required.
//#define ADEPT_FLOATING_POINT_TYPE float
//#define ADEPT_FLOATING_POINT_TYPE long double

// Thread-local storage is used for the global Stack pointer to ensure
// thread safety.  Thread-local variables are declared in different
// ways by different compilers, the most common ones being detected in
// section 4 below.  Some platforms (particularly some Mac platforms)
// do not implement thread-local storage, and therefore on Mac
// thread-local storage is disabled. If you want to manually specify
// how thread-local storage is declared, you may do it here,
// e.g. using the C++11 keyword "thread_local".  If thread-local
// storage is not available on your platform but is not detected in
// section 4, and consequently you cannot get the code to compile,
// then you can make an empty declaration here.
//#define ADEPT_THREAD_LOCAL thread_local

// User files can be compiled with ADEPT_NO_AUTOMATIC_DIFFERENTIATION,
// which makes the aReal type behave as a double.  The following
// #ifndef wraps almost all of this header file.
#ifndef ADEPT_NO_AUTOMATIC_DIFFERENTIATION

// ---------------------------------------------------------------------
// SECTION 3: Header files
// ---------------------------------------------------------------------

#include <cmath>
#include <stdlib.h>
#include <iostream>
#include <typeinfo>
#include <utility>
#include <string>
#include <vector>
#include <list>
#include <exception>
#include <cstddef>

#ifdef ADEPT_STACK_STORAGE_STL
#include <valarray>
#endif


// ---------------------------------------------------------------------
// SECTION 4: Miscellaneous
// ---------------------------------------------------------------------

// The way thread-local variables are specified pre-C++11 is compiler
// specific.  You can specify this manually by defining the
// ADEPT_THREAD_LOCAL preprocessor variable (e.g. to "thread_local");
// otherwise it is defined here depending on your compiler
#ifndef ADEPT_THREAD_LOCAL
#if defined(__APPLE__)
// Thread-local storage typically does not work on Mac OS X so we turn
// it off and provide a blank definition of ADEPT_THREAD_LOCAL so that
// this file and adept.cpp will successfully compile
#define ADEPT_STACK_THREAD_UNSAFE 1
#define ADEPT_THREAD_LOCAL
#elif defined(_WIN32)
// Windows has a different way to specify thread-local storage from
// the GCC/Intel/Sun/IBM compilers.  Note that this is unified with
// C++11 but the older formats are still supported and it would be
// more complicated to check for C++11 support.
#define ADEPT_THREAD_LOCAL __declspec(thread)
#else
// The following should work on GCC/Intel/Sun/IBM compilers
#define ADEPT_THREAD_LOCAL __thread
#endif
#endif

namespace adept {

  // By default everything is double precision, but this precision can
  // be changed by defining ADEPT_FLOATING_POINT_TYPE
#ifdef ADEPT_FLOATING_POINT_TYPE
  typedef ADEPT_FLOATING_POINT_TYPE Real;
#else
  typedef double Real;
#endif

  // Used for all integer measures of array sizes and positions in an
  // array. Note that on some platforms std::size_t results in a
  // measurable slow-down compared to unsigned int
  //  typedef std::size_t Offset;
  typedef unsigned int Offset;
 
  // Declare a thread-safe and a thread-unsafe global pointer to the
  // current stack
  class Stack;
  extern ADEPT_THREAD_LOCAL Stack* _stack_current_thread;
  extern Stack* _stack_current_thread_unsafe;

  // Define ADEPT_ACTIVE_STACK to be the currently active version
  // regardless of whether we are in thread safe or unsafe mode
#ifdef ADEPT_STACK_THREAD_UNSAFE
#define ADEPT_ACTIVE_STACK adept::_stack_current_thread_unsafe
#else
#define ADEPT_ACTIVE_STACK adept::_stack_current_thread
#endif

  // Structure describing the LHS of a derivative expression.  For dx
  // = z dy + y dz, "offset" would be the location of dx in the
  // gradient list, and "end_plus_one" would be one plus the location
  // of the final operation (multiplier-derivative pair) on the RHS,
  // in this case y dz.
  struct Statement {
    Statement() { }
    Statement(Offset offset_, Offset end_plus_one_)
      : offset(offset_), end_plus_one(end_plus_one_) { }
    Offset offset;
    Offset end_plus_one;
  };

  // Structure holding a fixed-size array of objects (intended for
  // double or float)
  template<int Size, class Type>
  struct Block {
    Block() { zero(); }
    const Type& operator[](Offset i) const { return data[i]; }
    Type& operator[](Offset i) { return data[i]; }
    void zero() { for (Offset i = 0; i < Size; i++) data[i] = 0.0; }
    Type data[Size];
  };

  // Structure for describing a gap in the current list of gradients
  struct Gap {
    Gap(Offset value) : start(value), end(value) {}
    Gap(Offset start_, Offset end_) : start(start_), end(end_) {}
    Offset start;
    Offset end;
  };

  // ---------------------------------------------------------------------
  // SECTION 5: Exceptions
  // ---------------------------------------------------------------------

  // Adept functions can throw exceptions that are all derived from
  // the adept::autodiff_exception type, and all implement the
  // "what()" function to return an error message. First we define the
  // autodiff_exception type:
  class autodiff_exception : public std::exception {
  public:
    virtual const char* what() const throw() {
      return message_;
    }
  protected:
    const char* message_;
  };

  // Now we define the various specific exceptions that can be thrown.
  class gradient_out_of_range : public autodiff_exception {
  public:
    gradient_out_of_range(const char* message 
			  = "Gradient index out of range: probably aReal objects have been created after a set_gradient(s) call")
    { message_ = message; }
  };

  class gradients_not_initialized : public autodiff_exception {
  public:
    gradients_not_initialized(const char* message 
			      = "Gradients not initialized: at least one call to set_gradient(s) is needed before a forward or reverse pass")
    { message_ = message; }
  };

  class stack_already_active : public autodiff_exception {
  public:
    stack_already_active(const char* message 
			 = "Attempt to activate an adept::Stack when one is already active in this thread")
    { message_ = message; }
  };

  class dependents_or_independents_not_identified : public autodiff_exception {
  public:
    dependents_or_independents_not_identified(const char* message 
		 = "Dependent or independent variables not identified before a Jacobian computation")
    { message_ = message; }
  };

  class wrong_gradient : public autodiff_exception {
  public:
    wrong_gradient(const char* message
		   = "Wrong gradient: append_derivative_dependence called on a different aReal object from the most recent add_derivative_dependence call")
    { message_ = message; }
  };

  class non_finite_gradient : public autodiff_exception {
  public:
    non_finite_gradient(const char* message
			= "A non-finite gradient has been computed")
    { message_ = message; }
  };

  class feature_not_available : public autodiff_exception {
  public:
    feature_not_available(const char* message = "Feature not available")
    { message_ = message; }
  };



  // ---------------------------------------------------------------------
  // SECTION 6: Definition of Stack class
  // ---------------------------------------------------------------------

  // Class containing derivative information of an algorithm, from which
  // the Jacobian matrix can be constructed, as well as tangent-linear
  // and adjoint operations being carried out for suitable input
  // derivatives.  Member functions not defined here are in
  // stack.cpp

  class Stack {
  public:
    typedef std::list<Gap> GapList;
    typedef std::list<Gap>::iterator GapListIterator;


    // Only one constructor, which is normally called with no
    // arguments, but if "false" is provided as the argument it will
    // construct as normal but not attempt to make itself the active stack
    Stack(bool activate_immediately = true) :
#ifndef ADEPT_STACK_STORAGE_STL
      statement_(0), gradient_(0),
      multiplier_(0), offset_(0),
#endif
      most_recent_gap_(gap_list_.end()),
      n_statements_(0), n_allocated_statements_(0),
      n_operations_(0), n_allocated_operations_(0),
      i_gradient_(0), n_allocated_gradients_(0), max_gradient_(0),
      n_gradients_registered_(0),
      gradients_initialized_(false), 
#ifdef ADEPT_STACK_THREAD_UNSAFE
      is_thread_unsafe_(true),
#else
      is_thread_unsafe_(false),
#endif
      is_recording_(true),
      // Since the library might be compiled with OpenMP support and
      // subsequent programs without, we need to tell the library via
      // the following variable
#ifdef _OPENMP
      have_openmp_(true),
#else
      have_openmp_(false),
#endif
      openmp_manually_disabled_(false)
    { 
      initialize(ADEPT_INITIAL_STACK_LENGTH);
      if (activate_immediately) {
	activate();
      }
    }
  
    // Destructor
    ~Stack();

    // This function is no longer available
    void start(Offset n = ADEPT_INITIAL_STACK_LENGTH) {
      throw (feature_not_available("The Stack::start() function has been removed since Adept version 1.0: see the documentation about how to use Stack::new_recording()"));
    }

    // Push an operation (i.e. a multiplier-gradient pair) on to the
    // stack.  We assume here that check_space() as been called before
    // so there is enough space to hold these elements.
  void push_rhs(const Real& multiplier, const Offset& gradient_offset) {
#ifdef ADEPT_REMOVE_NULL_STATEMENTS
    // If multiplier==0 then the resulting statement would have no
    // effect so we can speed up the subsequent adjoint/jacobian
    // calculations (at the expense of making this critical part of
    // the code slower)
    if (multiplier != 0.0) {
#endif

#ifdef ADEPT_STACK_STORAGE_STL
      multiplier_.push_back(multiplier);
      offset_.push_back(gradient_offset);
      n_operations_++;
#else
      multiplier_[n_operations_] = multiplier;
      offset_[n_operations_++] = gradient_offset;
#endif

#ifdef ADEPT_TRACK_NON_FINITE_GRADIENTS
      if (!std::isfinite(multiplier) || std::isinf(multiplier)) {
	throw(non_finite_gradient());
      }
#endif
      
#ifdef ADEPT_REMOVE_NULL_STATEMENTS
    }
#endif
  }

    // Push a statement on to the stack: this is done after a sequence
    // of operation pushes; gradient_offset is the offset of the
    // gradient on the LHS of the expression, while the "end_plus_one"
    // element is simply the current length of the operation list
    void push_lhs(const Offset& gradient_offset) {
#ifdef ADEPT_STACK_STORAGE_STL
      statement_.push_back(Statement(gradient_offset, n_operations_));
      n_statements_++;
#else
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
      if (n_statements_ >= n_allocated_statements_) {
	grow_statement_stack();
      }
#endif
      statement_[n_statements_].offset = gradient_offset;
      statement_[n_statements_++].end_plus_one = n_operations_;
#endif
    }

    // After a sequence of operation pushes, we may append these to
    // the previous statement by calling this function.
    // gradient_offset is the offset of the gradient on the LHS of the
    // statement: if this does not match the LHS of the previous
    // statement then this is an error and "false" will be returned. A
    // "true" return value indicates success.
    bool update_lhs(const Offset& gradient_offset) {
      if (statement_[n_statements_-1].offset != gradient_offset) {
	return false;
      }
      else {
	statement_[n_statements_-1].end_plus_one = n_operations_;
	return true;
      }
    }

    // When an aReal object is created it is registered on the stack
    // and keeps a copy of its location, which is returned from this
    // function
    Offset register_gradient() {
      Offset return_val;
#ifdef ADEPT_RECORDING_PAUSABLE
      if (is_recording()) {
#endif
	n_gradients_registered_++;
	if (gap_list_.empty()) {
	  // Add to end of gradient vector
	  i_gradient_++;
	  if (i_gradient_ > max_gradient_) {
	    max_gradient_ = i_gradient_;
	  }
	  return_val = i_gradient_-1;
	}
	else {
	  // Insert in a gap
	  Gap& first_gap = gap_list_.front();
	  return_val = first_gap.start;
	  first_gap.start++;
	  if (first_gap.start > first_gap.end) {
	    // Gap has closed: remove it from the list, after checking
	    // if it had been stored as the gap that had most recently
	    // grown
	    if (most_recent_gap_ == gap_list_.begin()) {
	      most_recent_gap_ = gap_list_.end();
	    }
	    gap_list_.pop_front();
	  }
	}
#ifdef ADEPT_RECORDING_PAUSABLE
      }
      else {
	return_val = 0;
      }
#endif
      return return_val;
    }

    // When an aReal object is destroyed it is unregistered from the
    // stack. If it is at the top of the stack then the stack pointer
    // can be decremented so that the space can be used by another
    // object. A gap can appear in the stack if an active object (or
    // array of active objects) is returned from a function, so we
    // need to keep track of a "gap" appearing in the stack. If the
    // user uses new and delete without any regard for this "last-in
    // first-out" preference then the number of gradients that are
    // allocated in the reverse pass may be larger than needed.
    void unregister_gradient(const Offset& gradient_offset) {
      n_gradients_registered_--;
      if (gradient_offset+1 == i_gradient_) {
	// Gradient to be unregistered is at the top of the stack
	i_gradient_--;
	if (!gap_list_.empty()) {
	  Gap& last_gap = gap_list_.back();
	  if (i_gradient_ == last_gap.end+1) {
	    // We have unregistered the elements between the "gap" of
	    // unregistered element and the top of the stack, so can
	    // set the variables indicating the presence of the gap to
	    // zero
	    i_gradient_ = last_gap.start;
	    GapListIterator it = gap_list_.end();
	    it--;
	    if (most_recent_gap_ == it) {
	      most_recent_gap_ = gap_list_.end();
	    }
	    gap_list_.pop_back();
	  }
	}
      }
      else { // Gradient to be unregistered not at top of stack
	// In the less common situation that the gradient is not at
	// the top of the stack, the task of unregistering is a bit
	// more involved, so we carry it out in a non-inline function
	// to avoid code bloat
	unregister_gradient_not_top(gradient_offset);
      }
    }

    // Unregister a gradient that is not at the top of the stack
    void unregister_gradient_not_top(const Offset& gradient_offset);

    // Set the gradients in the list with offsets between start and
    // end_plus_one-1 to the values pointed to by "gradient"
    void set_gradients(Offset start, Offset end_plus_one,
		       const Real* gradient) {
      // Need to initialize the gradient list if not already done
      if (!gradients_are_initialized()) {
	initialize_gradients();
      }
      if (end_plus_one > max_gradient_) {
	throw(gradient_out_of_range());
      }
      for (Offset i = start, j = 0; i < end_plus_one; i++, j++) {
	gradient_[i] = gradient[j];
      }
    }

    // Get the gradients in the list with offsets between start and
    // end_plus_one-1 and put them in the location pointed to by
    // "gradient"
    void get_gradients(Offset start, Offset end_plus_one,
		       Real* gradient) const {
      if (!gradients_are_initialized()) {
	throw(gradients_not_initialized());
      }
      if (end_plus_one > max_gradient_) {
	throw(gradient_out_of_range());
      }
      for (Offset i = start, j = 0; i < end_plus_one; i++, j++) {
	gradient[j] = gradient_[i];
      }
    }

    // Run the tangent-linear algorithm on the gradient list; normally
    // this call is preceded calls to set_gradient to load input
    // gradients and followed by calls to get_gradient to extract
    // gradients
    void compute_tangent_linear();
    void forward() { return compute_tangent_linear(); }

    // Run the adjoint algorithm on the gradient list; normally this
    // call is preceded calls to set_gradient to load input gradient
    // and followed by calls to get_gradient to extract gradient
    void compute_adjoint();
    void reverse() { return compute_adjoint(); }

    // Return the number of independent and dependent variables that
    // have been identified
    Offset n_independent() { return independent_offset_.size(); }
    Offset n_dependent() { return dependent_offset_.size(); }

    // Compute the Jacobian matrix; note that jacobian_out must be
    // allocated to be of size m*n, where m is the number of dependent
    // variables and n is the number of independents. The independents
    // and dependents must have already been identified with the
    // functions "independent" and "dependent", otherwise this
    // function will throw a
    // "dependents_or_independents_not_identified" exception. In the
    // resulting matrix, the "m" dimension of the matrix varies
    // fastest. This is implemented by calling one of jacobian_forward
    // and jacobian_reverse, whichever would be faster.
    void jacobian(Real* jacobian_out);

    // Compute the Jacobian matrix, but explicitly specify whether
    // this is done with repeated forward or reverse passes.
    void jacobian_forward(Real* jacobian_out);
    void jacobian_reverse(Real* jacobian_out);

    // Return maximum number of OpenMP threads to be used in Jacobian
    // calculation
    int max_jacobian_threads() const;

    // Set the maximum number of threads to be used in Jacobian
    // calculations, if possible. A value of 1 indicates that OpenMP
    // will not be used, while a value of 0 indicates that the number
    // will match the number of available processors. Returns the
    // maximum that will be used, which will be 1 if the Adept library
    // was compiled without OpenMP support. Note that a value of 1
    // will disable the use of OpenMP with Adept, so Adept will then
    // use no OpenMP directives or function calls. Note that if in
    // your program you use OpenMP with each thread performing
    // automatic differentiaion with its own independent Adept stack,
    // then typically only one OpenMP thread is available for each
    // Jacobian calculation, regardless of whether you call this
    // function.
    int set_max_jacobian_threads(int n);

    // In order to compute the jacobian we need to first declare which
    // active variables are independent (x) and which are dependent
    // (y). First, the following two functions declare an individual
    // active variable and an array of active variables to be
    // independent. Note that we use templates here because aReal has
    // not been defined.
    template <class A>
    void independent(const A& x) {
      independent_offset_.push_back(x.gradient_offset());
    }
    template <class A>
    void independent(const A* x, Offset n) {
      for (Offset i = 0; i < n; i++) {
	independent_offset_.push_back(x[i].gradient_offset());
      }
    }

    // Likewise, delcare the dependent variables
    template <class A>
    void dependent(const A& x) {
      dependent_offset_.push_back(x.gradient_offset());
    }
    template <class A>
    void dependent(const A* x, Offset n) {
      for (Offset i = 0; i < n; i++) {
	dependent_offset_.push_back(x[i].gradient_offset());
      }
    }

    // Print various bits of information about the Stack to the
    // specified stream (or standard output if not specified). The
    // same behaviour can be obtained by "<<"-ing the Stack to a
    // stream.
    void print_status(std::ostream& os = std::cout) const;

    // Print each derivative statement to the specified stream (or
    // standard output if not specified)
    void print_statements(std::ostream& os = std::cout) const;

    // Print the current gradient list to the specified stream (or
    // standard output if not specified); returns true on success or
    // false if no gradients have been initialized
    bool print_gradients(std::ostream& os = std::cout) const;

    // Print a list of the gaps in the gradient list
    void print_gaps(std::ostream& os = std::cout) const;

    // Clear the gradient list enabling a new adjoint or
    // tangent-linear computation to be performed with the same
    // recording
    void clear_gradients() {
      gradients_initialized_ = false;
    }

    // Clear the list of independent variables, in order that a
    // different Jacobian can be computed from the same recording
    void clear_independents() {
      independent_offset_.clear();
    }

    // Clear the list of dependent variables, in order that a
    // different Jacobian can be computed from the same recording
    void clear_dependents() {
      dependent_offset_.clear();
    }

    // Function now removed
    void clear() {
      throw (feature_not_available("The Stack::clear() function has been removed since Adept version 1.0: see the documentation about how to use Stack::new_recording()"));
    }
    // Function now removed
    void clear_statements() {
      throw (feature_not_available("The Stack::clear_statements() function has been removed since Adept version 1.0: see the documentation about how to use Stack::new_recording()"));
    }

    // Make this stack "active" by copying its "this" pointer to a
    // global variable; this makes it the stack that aReal objects
    // subsequently interact with when being created and participating
    // in mathematical expressions
    void activate();

    // This stack will stop being the one that aReal objects refer
    // to; this may be useful if the thread needs to use another stack
    // object for the next algorithm
    void deactivate() {
      if (is_active()) {
	ADEPT_ACTIVE_STACK = 0;
      }
    }

    // Return true if the Stack is "active", false otherwise
    bool is_active() const {
      return (ADEPT_ACTIVE_STACK == this);
    }

    // Clear the contents of the various lists ready for a new
    // recording
    void new_recording() {
#ifdef ADEPT_STACK_STORAGE_STL
      // If we use STL containers then the clear() function sets their
      // size to zero but leaves the memory allocated
      statement_.clear();
      multiplier_.clear();
      offset_.clear();
#endif
      clear_independents();
      clear_dependents();
      clear_gradients();
      // Set the recording indices to zero
      n_operations_ = 0;
      n_statements_ = 0;
      // i_gradient_ is the maximum index of all currently constructed
      // aReal objects and max_gradient_ is the maximum index of all
      // that were used in a recording.  Thus when deleting the
      // recording we need to set max_gradient_ to i_gradient_ or a
      // little more.
      max_gradient_ = i_gradient_+1;
      // Insert a null statement
      //    std::cerr << "Inserting a null statement; when is this needed?\n";
      push_lhs(-1);
    }

    // Are gradients to be computed?  The default is "true", but if
    // ADEPT_RECORDING_PAUSABLE is defined then this may
    // be false
    bool is_recording() const {
#ifdef ADEPT_RECORDING_PAUSABLE
      return is_recording_;
#else
      return true;
#endif
    }

    // Stop recording gradient information, enabling a piece of active
    // code to be run without the stack information being stored. This
    // only works if ADEPT_RECORDING_PAUSABLE has been defined.
    bool pause_recording() {
#ifdef ADEPT_RECORDING_PAUSABLE
      is_recording_ = false;
      return true;
#else
      return false;
#endif
    }
    // Continue recording gradient information after a previous
    // pause_recording() call. This only works if
    // ADEPT_RECORDING_PAUSABLE has been defined.
    bool continue_recording() {
#ifdef ADEPT_RECORDING_PAUSABLE
      is_recording_ = true;
      return true;
#else
      return false;
#endif
    }

    // Have the gradients been initialized?
    bool gradients_are_initialized() const { return gradients_initialized_; }

    // Return the number of statements, operations, and how much
    // memory has been allocated for each
    Offset n_statements() const { return n_statements_; }
    Offset n_allocated_statements() const { return n_allocated_statements_; }
    Offset n_operations() const { return n_operations_; }
    Offset n_allocated_operations() const { return n_allocated_operations_; }

    // Return the size of the two dimensions of a Jacobian matrix
    Offset n_independents() const { return independent_offset_.size(); }
    Offset n_dependents() const { return dependent_offset_.size(); }

    // Return the maximum number of gradients required to perform
    // adjoint calculation
    Offset max_gradients() const { return max_gradient_; }

    // Return the index to the current gradient
    Offset i_gradient() const { return i_gradient_; }

    // Return the number of gradients memory has been allocated for
    Offset n_allocated_gradients() const { return n_allocated_gradients_; }

    // Return the number of bytes used
    std::size_t memory() const {
      std::size_t mem = n_statements()*sizeof(Offset)*2
	+ n_operations()*(sizeof(Real)+sizeof(Offset));
      if (gradients_are_initialized()) {
	mem += max_gradients()*sizeof(Real);
      }
      return mem;
    }

    // Return the number of gradients currently registered
    Offset n_gradients_registered() const { return n_gradients_registered_; }

    // Return the fraction of multipliers equal to the specified
    // number (usually -1, 0 or 1)
    Real fraction_multipliers_equal_to(Real val) {
      Offset sum = 0;
      for (Offset i = 0; i < n_operations_; i++) {
	if (multiplier_[i] == val) {
	  sum++;
	}
      }
      return static_cast<Real>(sum)/static_cast<Real>(n_operations_);
    }


    bool is_thread_unsafe() const { return is_thread_unsafe_; }

    const GapList& gap_list() const { return gap_list_; }

    // Memory to store statements and operations can be preallocated,
    // offering modest performance advantage if you define
    // ADEPT_MANUAL_MEMORY_ALLOCATION and know the maximum number of
    // statements and operations you will need
    void preallocate_statements(Offset n) {
      if (n_statements_+n+1 >= n_allocated_statements_) {
	grow_statement_stack(n);
      }
    }
    void preallocate_operations(Offset n) {
      if (n_allocated_operations_ < n_operations_+n+1) {
	grow_operation_stack(n);
      }      
    }

#ifndef ADEPT_STACK_STORAGE_STL
    // Check whether the operation stack contains enough space for n
    // new operations; if not, grow it
    void check_space(const Offset& n) {
      if (n_allocated_operations_ < n_operations_+n+1) {
	grow_operation_stack(n);
      }
    }

private:
    // This function is called by the constructor to initialize
    // memory, which can be grown subsequently
    void initialize(Offset n);

    // Grow the capacity of the operation or statement stacks to hold
    // a minimum of "min" elements. If min=0 then the stacks are
    // doubled in size.
    void grow_operation_stack(Offset min = 0);
    void grow_statement_stack(Offset min = 0);

#else // NOT ADEPT_STACK_STORAGE_DYNAMIC
    // For non-dynamic storage, check_space does nothing
    void check_space(const Offset& n) { }
#endif

    // Initialize the vector of gradients ready for the adjoint
    // calculation
    void initialize_gradients();

    // Set to zero the gradients required by a Jacobian calculation
    void zero_gradient_multipass() {
      for (Offset i = 0; i < gradient_multipass_.size(); i++) {
	gradient_multipass_[i].zero();
      }
    }

    // OpenMP versions of the forward and reverse Jacobian functions,
    // which are called from the jacobian_forward and jacobian_reverse
    // if OpenMP is enabled
    void jacobian_forward_openmp(Real* jacobian_out);
    void jacobian_reverse_openmp(Real* jacobian_out);

  private:
    // --- DATA SECTION ---

#ifdef ADEPT_STACK_STORAGE_STL
    // Data are stored using standard template library containers
    std::vector<Statement> statement_;
    std::valarray<Real> gradient_;
    std::vector<Real> multiplier_;
    std::vector<Offset> offset_;
#else
    // Data are stored as dynamically allocated arrays
    Statement* __restrict statement_ ;
    Real* __restrict gradient_;
    Real* __restrict multiplier_;
    Offset* __restrict offset_;
#endif
    // For Jacobians we process multiple rows/columns at once so need
    // what is essentially a 2D array
    std::vector<Block<ADEPT_MULTIPASS_SIZE,Real> > gradient_multipass_;
    // Offsets of the independent and dependent variables
    std::vector<Offset> independent_offset_;
    std::vector<Offset> dependent_offset_;
    // Keep a record of gaps in the gradient array to ensure that gaps
    // are filled
    GapList gap_list_;
    //    Gap* most_recent_gap_;
    GapListIterator most_recent_gap_;

    Offset n_statements_;           // Number of statements
    Offset n_allocated_statements_; // Space allocated for statements
    Offset n_operations_;           // Number of operations
    Offset n_allocated_operations_; // Space allocated for statements
    Offset i_gradient_;             // Current number of gradients
    Offset n_allocated_gradients_;  // Number of allocated gradients
    Offset max_gradient_;           // Max number of gradients to store
    Offset n_gradients_registered_; // Number of gradients registered
    bool gradients_initialized_;    // Have the gradients been
				    // initialized?
    bool is_thread_unsafe_;
    bool is_recording_;
    bool have_openmp_;              // true if this header file
				    // compiled with -fopenmp
    bool openmp_manually_disabled_; // true if used called
				    // set_max_jacobian_threads(1)
};


  // ---------------------------------------------------------------------
  // SECTION 7: Definition of Expression types
  // ---------------------------------------------------------------------

  // In this section the expression template approach is employed:
  // each operator and mathematical function returns a templated type,
  // rather than simply the numerical result of the operation

  // What type does the value() member function of each type of
  // expression return?
  //#define ADEPT_VALUE_RETURN_TYPE const Real&
#define ADEPT_VALUE_RETURN_TYPE Real

  class aReal;

  // The Expression type from which all other types of expression
  // derive. Each member function simply calls the specialized version
  // of the function according to the expression's true type, which is
  // given by its template argument.
  template<class A>
  struct Expression {
    // This indicates what type the expression resolves to, and allows
    // for future versions where there may be an underlying active
    // complex or single-precision type instead of double
    typedef aReal resolve_type;

    // Cast the expression to its true type, given by the template
    // argument
    const A& cast() const { return static_cast<const A&>(*this); }

    // Calculate the gradient of the mathematical operation that this
    // expression represents and pass the result to its argument (you
    // probably need to read the paper to understand why this is
    // useful). For functions f(a), pass df/da to the argument in the
    // first case and pass multiplier*df/da in the second case.
    void calc_gradient(Stack& stack) const {
      cast().calc_gradient(stack);
    }

    // As the previous but multiplying the gradient by "multiplier"
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      cast().calc_gradient(stack, multiplier);
    }

    // Return the numerical value of the expression
    ADEPT_VALUE_RETURN_TYPE value() const {
      return cast().value();
    }

    // Calculate the gradient and return the numerical value
    Real value_and_gradient(Stack& stack) const {
      cast().calc_gradient(stack);
      return cast().value();
    }

  private:
    // Intentionally inaccessible to prevent an expression appearing
    // on the left-hand-side of a statement
    Expression& operator=(const Expression&) { return *this; };
  };

  // Now define particular types of expression, using static
  // polymorphism via the Curiously Recurring Template Pattern

  // Add: an expression plus another expression
  template <class A, class B>
  struct Add : public Expression<Add<A,B> > {
    Add(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()) { }
    // If f(a,b) = a + b, df/da = 1 and likewise for df/db so simply
    // call a and b's versions of calc_gradient
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack);
      b_.calc_gradient(stack);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, multiplier);
      b_.calc_gradient(stack, multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return a_.value() + b_.value();
    }
  private:
    // Store constant references to the arguments of the addition
    const A& a_;
    const B& b_;
  };

  // Overload the addition operator for Expression arguments to return
  // an Add type
  template <class A, class B>
  inline
  Add<A,B> operator+(const Expression<A>& a,
		     const Expression<B>& b) {
    return Add<A,B>(a.cast(),b.cast());
  }

  // Subtract: an expression minus another expression
  template <class A, class B>
  struct Subtract : public Expression<Subtract<A,B> > {
    Subtract(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()) { }
    // If f(a,b) = a - b, df/da = 1 and df/db = -1
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack);
      b_.calc_gradient(stack, -1.0);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, multiplier);
      b_.calc_gradient(stack, -multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return a_.value() - b_.value();
    }
  private:
    const A& a_;
    const B& b_;
  };

  // Overload subtraction operator for Expression arguments
  template <class A, class B>
  inline
  Subtract<A,B> operator-(const Expression<A>& a,
			  const Expression<B>& b) {
    return Subtract<A,B>(a.cast(),b.cast());
  }

  // Multiply: an expression multiplied by another expression
#ifdef ADEPT_MULTIPLY_PRECOMPUTES_RESULT
  // The first version precomputes the result, which should be optimal
  // if value() is called multiple times
  template <class A, class B>
  struct Multiply : public Expression<Multiply<A,B> > {
    Multiply(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()), result_(a_.value()*b_.value()) { }
    // If f(a,b) = a*b then df/da = b and df/db = a
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, b_.value());
      b_.calc_gradient(stack, a_.value());
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, b_.value()*multiplier);
      b_.calc_gradient(stack, a_.value()*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    const B& b_;
    Real result_;
  };
#else
  // The second version does not precompute the result
  template <class A, class B>
  struct Multiply : public Expression<Multiply<A,B> > {
    Multiply(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()) { }
    // If f(a,b) = a*b then df/da = b and df/db = a
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, b_.value());
      b_.calc_gradient(stack, a_.value());
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, b_.value()*multiplier);
      b_.calc_gradient(stack, a_.value()*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return a_.value() * b_.value();
    }
  private:
    const A& a_;
    const B& b_;
  };
#endif

  // Overload multiplication operator for Expression arguments
  template <class A, class B>
  inline
  Multiply<A,B> operator*(const Expression<A>& a,
			  const Expression<B>& b) {
    return Multiply<A,B>(a.cast(),b.cast());
  }

  // Divide: an expression divided by another expression
  template <class A, class B>
  struct Divide : public Expression<Divide<A,B> > {
    Divide(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()), one_over_b_(1.0/b_.value()),
	result_(a_.value()*one_over_b_) { }
    // If f(a,b) = a/b then df/da = 1/b and df/db = -a/(b*b)
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, one_over_b_);
      b_.calc_gradient(stack, -result_*one_over_b_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      Real tmp = multiplier*one_over_b_;
      a_.calc_gradient(stack, tmp);
      b_.calc_gradient(stack, -tmp*result_);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    const B& b_;
    Real one_over_b_;
    Real result_;
  };
  
  // Overload division operator for Expression arguments
  template <class A, class B>
  inline
  Divide<A,B> operator/(const Expression<A>& a,
			const Expression<B>& b) {
    return Divide<A,B>(a.cast(),b.cast());
  }

  // ScalarAdd: an expression plus a scalar
  template <class A>
  struct ScalarAdd : public Expression<ScalarAdd<A> > {
    ScalarAdd(const Expression<A>& a, const Real& b)
      : a_(a.cast()), result_(a_.value() + b) { }
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    Real result_;
  };

  // Overload addition operator for expression plus scalar and scalar
  // plus expression
  template <class A>
  inline
  ScalarAdd<A> operator+(const Expression<A>& a,
			 const Real& b) {
    return ScalarAdd<A>(a.cast(),b);
  }
  template <class A>
  inline
  ScalarAdd<A> operator+(const Real& b,
			 const Expression<A>& a) {
    return ScalarAdd<A>(a.cast(),b);
  }

  // Overload subtraction operator for expression minus scalar to
  // return a ScalarAdd object
  template <class A>
  inline
  ScalarAdd<A> operator-(const Expression<A>& a,
			 const Real& b) {
    return ScalarAdd<A>(a.cast(),-b);
  }

  // ScalarSubtract: scalar minus expression
  template <class B>
  struct ScalarSubtract : public Expression<ScalarSubtract<B> > {
    ScalarSubtract(const Real& a, const Expression<B>& b)
      : b_(b.cast()), result_(a - b_.value()) {}
    void calc_gradient(Stack& stack) const {
      b_.calc_gradient(stack, -1.0);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      b_.calc_gradient(stack, -multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const B& b_;
    Real result_;
  };

  // Overload subtraction operator for scalar minus expression
  template <class B>
  inline
  ScalarSubtract<B> operator-(const Real& a,
			      const Expression<B>& b) {
    return ScalarSubtract<B>(a, b.cast());
  }

  // ScalarMultiply: expression multiplied by scalar
  template <class A>
  struct ScalarMultiply
    : public Expression<ScalarMultiply<A> > {
    ScalarMultiply(const Expression<A>& a, const Real& b)
      : a_(a.cast()), b_(b) { }
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, b_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, multiplier*b_);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return a_.value() * b_;
    }
  private:
    const A& a_;
    Real b_;
  };

  // Overload multiplication operator for expression multiplied by
  // scalar and scalar multiplied by expression
  template <class A>
  inline
  ScalarMultiply<A> operator*(const Expression<A>& a,
			      const Real& b) {
    return ScalarMultiply<A>(a.cast(),b);
  }
  template <class A>
  inline
  ScalarMultiply<A> operator*(const Real& b,
			      const Expression<A>& a) {
    return ScalarMultiply<A>(a.cast(),b);
  }
  
  // Overload division operator for expression divided by scalar to
  // return ScalarMultiply object
  template <class A>
  inline
  ScalarMultiply<A> operator/(const Expression<A>& a,
			      const Real& b) {
    return ScalarMultiply<A>(a.cast(),1.0/b);
  }

  // ScalarDivide: scalar divided by expression
  template <class B>
  struct ScalarDivide : public Expression<ScalarDivide<B> > {
    ScalarDivide(const Real& a, const Expression<B>& b)
      : b_(b.cast()), one_over_b_(1.0/b_.value()), 
	result_(a * one_over_b_) { }
    // If f(a,b) = a/b then df/db = -a/(b*b)    
    void calc_gradient(Stack& stack) const {
      b_.calc_gradient(stack, -result_*one_over_b_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      b_.calc_gradient(stack, -multiplier*result_*one_over_b_);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const B& b_;
    Real one_over_b_;
    Real result_;
  };

  // Overload division operator for scalar divided by expression
  template <class B>
  inline
  ScalarDivide<B> operator/(const Real& a,
			    const Expression<B>& b) {
    return ScalarDivide<B>(a,b.cast());
  }
  
  // Conditional operators should behave exactly the same as with
  // non-active arguments so in each of the cases below the value()
  // function is called to extract the value of the expression
#define ADEPT_DEFINE_CONDITIONAL(OPERATOR, OP)			\
  template <class A, class B>					\
  inline							\
  bool OPERATOR(const Expression<A>& a,				\
		const Expression<B>& b) {			\
    return a.value() OP b.value();				\
  }								\
								\
  template <class A>						\
  inline							\
  bool OPERATOR(const Expression<A>& a, const Real& b) {	\
    return a.value() OP b;					\
  }								\
  								\
  template <class B>						\
  inline							\
  bool OPERATOR(const Real& a, const Expression<B>& b) {	\
    return a OP b.value();					\
  }

  ADEPT_DEFINE_CONDITIONAL(operator==, ==)
  ADEPT_DEFINE_CONDITIONAL(operator!=, !=)
  ADEPT_DEFINE_CONDITIONAL(operator>, >)
  ADEPT_DEFINE_CONDITIONAL(operator<, <)
  ADEPT_DEFINE_CONDITIONAL(operator>=, >=)
  ADEPT_DEFINE_CONDITIONAL(operator<=, <=)
  
#undef ADEPT_DEFINE_CONDITIONAL
  
  // UnaryMinus: negation of expression 
  template <class A>
  struct UnaryMinus : public Expression<UnaryMinus<A> > {
    UnaryMinus(const Expression<A>& a)
      : a_(a.cast()) { }
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, -1.0);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, -multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return -a_.value();
    }
  private:
    const A& a_;
  };
  
  // Overload unary minus of expression
  template <class A>
  inline
  UnaryMinus<A> operator-(const Expression<A>& a) {
    return UnaryMinus<A>(a.cast());
  }

  // Unary plus: returns the argument
  template <class A>
  inline
  A operator+(const Expression<A>& a) {
    return a;
  }

  // Exponential of an expression
  template <class A>
  struct Exp : public Expression<Exp<A> > {
    Exp(const Expression<A>& a)
      : a_(a.cast()), result_(exp(a.value())) { }
    // If f(a) = exp(a) then df/da = exp(a)
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, result_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, result_*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    Real result_;
  };
  
} // End namespace adept

// It is important to place overloads of mathematical functions in the
// global namespace.  If exp(Expression) was placed in the adept
// namespace then the Exp class (which is in the adept namespace would
// not be able to find the std::exp(double) function due to C++ name
// look-up rules.

// Overload exp for Expression objects
template <class A>
inline
adept::Exp<A> exp(const adept::Expression<A>& a) {
  return adept::Exp<A>(a.cast());
}


// Enable unary mathematical functions when the derivative is most
// easily written in terms of the argument of the function; note that
// the class is in the adept name space but the function is not.
#define ADEPT_DEFINE_UNARY_FUNCTION(OP,FUNC,DERIVATIVE)		\
  namespace adept {						\
    template <class A>						\
    struct OP : public Expression<OP<A> > {			\
      OP(const Expression<A>& a)				\
	: a_(a.cast()), result_(FUNC(a_.value())) { }		\
      void calc_gradient(Stack& stack) const {			\
	a_.calc_gradient(stack, DERIVATIVE);			\
      }								\
      void calc_gradient(Stack& stack,				\
			 const Real& multiplier) const {	\
	a_.calc_gradient(stack, (DERIVATIVE)*multiplier);	\
      }								\
      ADEPT_VALUE_RETURN_TYPE value() const {			\
	return result_;						\
      }								\
    private:							\
    const A& a_;						\
    Real result_;						\
    };								\
  }								\
  template <class A>						\
  inline							\
  adept:: OP<A> FUNC(const adept::Expression<A>& a) {		\
    return adept:: OP<A>(a.cast());				\
  }

// The final argument is the value of the derivative
ADEPT_DEFINE_UNARY_FUNCTION(Log,  log,  1.0/a_.value())
ADEPT_DEFINE_UNARY_FUNCTION(Log10,log10,0.43429448190325182765/a_.value())
ADEPT_DEFINE_UNARY_FUNCTION(Log2, log2, 1.44269504088896340737/a_.value())
ADEPT_DEFINE_UNARY_FUNCTION(Sin,  sin,  cos(a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Cos,  cos,  -sin(a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Asin, asin, 1.0/sqrt(1.0-a_.value()*a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Acos, acos, -1.0/sqrt(1.0-a_.value()*a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Atan, atan, 1.0/(1+a_.value()*a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Sinh, sinh, cosh(a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Cosh, cosh, sinh(a_.value()))
// Note that we use first define the case for fabs here, because abs
// is likely to call the integer version from the C library
ADEPT_DEFINE_UNARY_FUNCTION(Abs,  fabs,  (a_.value()>0.0)-(a_.value()<0.0))
ADEPT_DEFINE_UNARY_FUNCTION(Expm1,expm1, exp(a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Exp2, exp2,  0.6931471805599453094172321214581766*exp2(a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Log1p,log1p, 1.0/(1.0+a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Asinh, asinh, 1.0/sqrt(a_.value()*a_.value()+1.0))
ADEPT_DEFINE_UNARY_FUNCTION(Acosh, acosh, 1.0/sqrt(a_.value()*a_.value()-1.0))
ADEPT_DEFINE_UNARY_FUNCTION(Atanh, atanh, 1.0/(1.0-a_.value()*a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Erf, erf, 1.12837916709551*exp(-a_.value()*a_.value()))
ADEPT_DEFINE_UNARY_FUNCTION(Erfc, erfc, -1.12837916709551*exp(-a_.value()*a_.value()))


#undef ADEPT_DEFINE_UNARY_FUNCTION

// Need both fabs and abs for C compatibility, so get abs to return an
// Abs object (which uses fabs internally, so doesn't incorrectly call
// the integer version)
template <class A>
inline
adept::Abs<A> abs(const adept::Expression<A>& a) {
  return adept::Abs<A>(a.cast());
}

// Need to add ceil, floor...
// Lots more math function in math.h: bessel functions etc...

template <class A>
inline
bool
isinf(const adept::Expression<A>& a) {
  return std::isinf(a.value());
}

template <class A>
inline
bool
isnan(const adept::Expression<A>& a) {
  return std::isnan(a.value());
}

template <class A>
inline
bool
isfinite(const adept::Expression<A>& a) {
  return std::isfinite(a.value());
}

template <class A>
inline
bool
__isinf(const adept::Expression<A>& a) {
  return __isinf(a.value());
}

template <class A>
inline
bool
__isnan(const adept::Expression<A>& a) {
  return __isnan(a.value());
}

template <class A>
inline
bool
__isfinite(const adept::Expression<A>& a) {
  return __isfinite(a.value());
}


// Enable mathematical functions when the derivative is most easily
// written in terms of the return value of the function
#define ADEPT_DEFINE_UNARY_FUNCTION2(OP,FUNC,DERIVATIVE)	\
  namespace adept {						\
    template <class A>						\
    struct OP : public Expression<OP<A> > {			\
      OP(const Expression<A>& a)				\
	: a_(a.cast()), result_(FUNC(a.value())) { }		\
      void calc_gradient(Stack& stack) const {			\
	a_.calc_gradient(stack, DERIVATIVE);			\
      }								\
      void calc_gradient(Stack& stack,				\
			 const Real& multiplier) const {	\
	a_.calc_gradient(stack, (DERIVATIVE)*multiplier);	\
      }								\
      ADEPT_VALUE_RETURN_TYPE value() const {			\
	return result_;						\
      }								\
    private:							\
    const A& a_;						\
    Real result_;						\
    };								\
  }								\
  template <class A>						\
  inline							\
  adept:: OP<A> FUNC(const adept::Expression<A>& a) {		\
    return adept:: OP<A>(a.cast());				\
  }

// Not much in this category...
ADEPT_DEFINE_UNARY_FUNCTION2(Sqrt, sqrt, 0.5/result_)
ADEPT_DEFINE_UNARY_FUNCTION2(Cbrt, cbrt,  (1.0/3.0)/(result_*result_))
ADEPT_DEFINE_UNARY_FUNCTION2(Tanh, tanh, 1.0 - result_*result_)

#undef ADEPT_DEFINE_UNARY_FUNCTION2


// Enable mathematical functions when derivative is a little more
// complicated
#define ADEPT_DEFINE_UNARY_FUNCTION3(OP,FUNC,DERIV1, DERIV2)	\
  namespace adept {						\
    template <class A>						\
    struct OP : public Expression<OP<A> > {			\
      OP(const Expression<A>& a)				\
	: a_(a.cast()), result_(FUNC(a_.value())) { }		\
      void calc_gradient(Stack& stack) const {			\
	DERIV1;							\
	a_.calc_gradient(stack, DERIV2);			\
      }								\
      void calc_gradient(Stack& stack,				\
			 const Real& multiplier) const {	\
	DERIV1;							\
	a_.calc_gradient(stack, (DERIV2)*multiplier);		\
      }								\
      ADEPT_VALUE_RETURN_TYPE value() const {			\
	return result_;						\
      }								\
    private:							\
    const A& a_;						\
    Real result_;						\
    };								\
  }								\
  template <class A>						\
  inline							\
  adept:: OP<A> FUNC(const adept::Expression<A>& a) {		\
    return adept:: OP<A>(a.cast());				\
  }

ADEPT_DEFINE_UNARY_FUNCTION3(Tan,  tan, Real tmp = 1/cos(a_.value()), tmp * tmp)

#undef ADEPT_DEFINE_UNARY_FUNCTION3

namespace adept {
  // Pow: an expression to the power of another expression
  template <class A, class B>
  struct Pow : public Expression<Pow<A,B> > {
    Pow(const Expression<A>& a, const Expression<B>& b)
      : a_(a.cast()), b_(b.cast()), 
	result_(pow(a_.value(), b_.value())) { };
    // If f(a,b)=pow(a,b) then df/da=b*pow(a,b-1) and df/db=log(a)*pow(a,b)
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, b_.value()*pow(a_.value(),b_.value()-1.0));
      b_.calc_gradient(stack, log(a_.value())*result_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, b_.value()*pow(a_.value(), 
					     b_.value()-1.0)*multiplier);
      b_.calc_gradient(stack, log(a_.value())*result_*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    const B& b_;
    Real result_;
  };
  
  // PowScalarExponent: an expression to the power of a scalar
  template <class A>
  struct PowScalarExponent : public Expression<PowScalarExponent<A> > {
    PowScalarExponent(const Expression<A>& a, const Real& b)
      : a_(a.cast()), b_(b), result_(pow(a_.value(), b)) {}
    void calc_gradient(Stack& stack) const {
      a_.calc_gradient(stack, b_*pow(a_.value(),b_-1.0));
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      a_.calc_gradient(stack, b_*pow(a_.value(), b_-1.0)*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    const A& a_;
    Real b_;
    Real result_;
  };

  // PowScalarBase: a scalar to the power of an expression
  template <class B>
  struct PowScalarBase : public Expression<PowScalarBase<B> > {
    PowScalarBase(const Real& a, const Expression<B>& b)
      : a_(a), b_(b.cast()), result_(pow(a_, b_.value())) { }
    void calc_gradient(Stack& stack) const {
      b_.calc_gradient(stack, log(a_)*result_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      b_.calc_gradient(stack, log(a_)*result_*multiplier);
    }
    ADEPT_VALUE_RETURN_TYPE value() const {
      return result_;
    }
  private:
    Real a_;
    const B& b_;
    Real result_;
  };
} // End namespace adept

// Overload pow for Expression arguments
template <class A, class B>
inline
adept::Pow<A,B> pow(const adept::Expression<A>& a,
		    const adept::Expression<B>& b) {
  return adept::Pow<A,B>(a.cast(),b.cast());
}

// Overload pow for expression to the power of scalar
template <class A>
inline
adept::PowScalarExponent<A> pow(const adept::Expression<A>& a, 
				const adept::Real& b) {
  return adept::PowScalarExponent<A>(a.cast(),b);
}

// Overload pow for scalar to the power of an expression
template <class B>
inline
adept::PowScalarBase<B> pow(const adept::Real& a,
			    const adept::Expression<B>& b) {
  return adept::PowScalarBase<B>(a, b.cast());
}

// If any further functions are added, remember to define a matching
// Trait specialization


// ---------------------------------------------------------------------
// SECTION 8: Definition of Traits
// ---------------------------------------------------------------------

namespace adept {
  // We want Traits<A>::n_active_variables to be defined at compile
  // time as the number of active variables in a particular expression
  // type A. This is done by defining a Traits type and specializing
  // it for each of the classes representing types of expression.

  template<class A>
  struct Traits {
    // This will not compile if the relevant trait is not defined for
    // a particular function, because n_active_variables is
    // intentionally not present
  };
  
  // aReal is an active variable so n_active_variables is 1
  template<>
  struct Traits<aReal> {
    enum { n_active_variables = 1 }; 
  };
  
  // For an arbitrary binary operation, the number of active variables
  // is the sum of the number of active variables in the two arguments
#define ADEPT_DEFINE_BINARY_TRAIT(OP)			\
  template<class A, class B>				\
  struct Traits<OP<A,B> > {				\
    enum { n_active_variables				\
	   = Traits<A>::n_active_variables		\
	   + Traits<B>::n_active_variables };		\
  };
  ADEPT_DEFINE_BINARY_TRAIT(Add)
  ADEPT_DEFINE_BINARY_TRAIT(Subtract)
  ADEPT_DEFINE_BINARY_TRAIT(Multiply)
  ADEPT_DEFINE_BINARY_TRAIT(Divide)
  ADEPT_DEFINE_BINARY_TRAIT(Pow)
  
#undef ADEPT_DEFINE_BINARY_TRAIT

  // For an arbitrary unary operation, the number of active variables
  // is equal to that for the argument
#define ADEPT_DEFINE_UNARY_TRAIT(OP)			\
  template<class A>					\
  struct Traits<OP<A> > {				\
    enum { n_active_variables				\
	   = Traits<A>::n_active_variables };		\
  };

  ADEPT_DEFINE_UNARY_TRAIT(ScalarAdd)
  ADEPT_DEFINE_UNARY_TRAIT(ScalarSubtract)
  ADEPT_DEFINE_UNARY_TRAIT(ScalarMultiply)
  ADEPT_DEFINE_UNARY_TRAIT(ScalarDivide)
  ADEPT_DEFINE_UNARY_TRAIT(UnaryMinus)
  ADEPT_DEFINE_UNARY_TRAIT(Exp)
  ADEPT_DEFINE_UNARY_TRAIT(Exp2)
  ADEPT_DEFINE_UNARY_TRAIT(Expm1)
  ADEPT_DEFINE_UNARY_TRAIT(Log)
  ADEPT_DEFINE_UNARY_TRAIT(Log2)
  ADEPT_DEFINE_UNARY_TRAIT(Log10)
  ADEPT_DEFINE_UNARY_TRAIT(Log1p)
  ADEPT_DEFINE_UNARY_TRAIT(Sqrt)
  ADEPT_DEFINE_UNARY_TRAIT(Cbrt)
  ADEPT_DEFINE_UNARY_TRAIT(Sin)
  ADEPT_DEFINE_UNARY_TRAIT(Cos)
  ADEPT_DEFINE_UNARY_TRAIT(Tan)
  ADEPT_DEFINE_UNARY_TRAIT(Asin)
  ADEPT_DEFINE_UNARY_TRAIT(Acos)
  ADEPT_DEFINE_UNARY_TRAIT(Atan)
  ADEPT_DEFINE_UNARY_TRAIT(Sinh)
  ADEPT_DEFINE_UNARY_TRAIT(Cosh)
  ADEPT_DEFINE_UNARY_TRAIT(Tanh)
  ADEPT_DEFINE_UNARY_TRAIT(Asinh)
  ADEPT_DEFINE_UNARY_TRAIT(Acosh)
  ADEPT_DEFINE_UNARY_TRAIT(Atanh)
  ADEPT_DEFINE_UNARY_TRAIT(Abs)
  ADEPT_DEFINE_UNARY_TRAIT(Erf)
  ADEPT_DEFINE_UNARY_TRAIT(Erfc)
  ADEPT_DEFINE_UNARY_TRAIT(PowScalarExponent)
  ADEPT_DEFINE_UNARY_TRAIT(PowScalarBase)
  
#undef ADEPT_DEFINE_UNARY_TRAIT


  // ---------------------------------------------------------------------
  // SECTION 9: Definition of aReal
  // ---------------------------------------------------------------------
  
  // The basic active type wrapping a Real (invariably double) number;
  // sometime this will be generalized to floats, complex<double>
  // etc. This inherits from Expression so that it can be used in
  // expressions.
  class aReal : public Expression<aReal> {
  public:
    // Constructor registers the new aReal object with the currently
    // active stack.  Note that this object is not explicitly
    // initialized with a particular number; the user should not
    // assume that it is set to zero but should later assign it to a
    // particular value. Otherwise in the reverse pass the
    // corresponding gradient will not be set to zero.
    aReal()
      : val_(0.0), gradient_offset_(ADEPT_ACTIVE_STACK->register_gradient()) { }
    
    // This constructor is invoked with either of the following:
    //   aReal x = 1.0;
    //   aReal x(1.0);
    aReal(const Real& rhs)
      : val_(rhs), gradient_offset_(ADEPT_ACTIVE_STACK->register_gradient())
    {
      // By pushing this to the statement stack without pushing
      // anything on to the operation stack we ensure that in the
      // reverse pass the gradient of this object will be set to zero
      // after it has been manipulated. This is important because the
      // gradient entry might be reused.
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
	ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
#endif
   }
    

#ifndef ADEPT_COPY_CONSTRUCTOR_ONLY_ON_RETURN_FROM_FUNCTION
    // Normal copy construction: register the new object then treat
    // this as an assignment
    aReal(const aReal& rhs) 
      : val_(0.0), gradient_offset_(ADEPT_ACTIVE_STACK->register_gradient())
    {
      *this = rhs;
    }
#else
    // If copy constructors for aReal objects are only used in the
    // return values for functions then we may make a slight
    // optimization by simply copying the gradient_offset, since we
    // can expect that the object being copied will shortly be
    // destructed. This will only lead to the right answer if your
    // code does not contain either of the following constructions:
    //   aReal x = y;
    //   aReal x(y);
    // where y is an aReal object.
    aReal(const aReal& rhs)
      : val_(rhs.value()), gradient_offset_(rhs.gradient_offset()) { }
#endif
    
    // Construction with an expression
    template<class R>
    aReal(const Expression<R>& rhs)
      : gradient_offset_(ADEPT_ACTIVE_STACK->register_gradient())
    {
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
      // Check there is enough space in the operation stack
      ADEPT_ACTIVE_STACK->check_space(Traits<R>::n_active_variables);
#endif
      // Get the value and push the gradients on to the operation
      // stack, thereby storing the right-hand-side of the statement
      val_ = rhs.value_and_gradient(*ADEPT_ACTIVE_STACK);
      // Push the gradient offet of this object on to the statement
      // stack, thereby storing the left-hand-side of the statement
      ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
      else {
	val_ = rhs.value();
      }
#endif
    }
    
    // Destructor simply unregisters the object from the stack,
    // freeing up the gradient offset for another
    ~aReal() {
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif

	ADEPT_ACTIVE_STACK->unregister_gradient(gradient_offset_);

#ifdef ADEPT_RECORDING_PAUSABLE
      }
#endif
    }

    // Assignment operator with an active variable on the rhs
    aReal& operator=(const aReal& rhs) {
      // Check there is space in the operation stack for one more
      // entry
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
	ADEPT_ACTIVE_STACK->check_space(1);
#endif
	// Same as construction with an expression (defined above)
	val_ = rhs.value_and_gradient(*ADEPT_ACTIVE_STACK);
	ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
      else {
	val_ = rhs.value();
      }
#endif
      return *this;
    }
    
    // Assignment operator with an inactive variable on the rhs
    aReal& operator=(const Real& rhs) {
      val_ = rhs;
      // Pushing the gradient offset on to the statement stack with no
      // corresponding operations ensures that the gradient will be
      // set to zero in the reverse pass when it is finished with
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
	ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
#endif
      return *this;
    }

    // Assignment operator with an expression on the rhs: very similar
    // to construction with an expression (defined above)
    template<class R>
    aReal& operator=(const Expression<R>& rhs) {
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
	ADEPT_ACTIVE_STACK->check_space(Traits<R>::n_active_variables);
#endif
	val_ = rhs.value_and_gradient(*ADEPT_ACTIVE_STACK);
	ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
      else {
	val_ = rhs.value();
      }
#endif
      return *this;
    }

    // All the compound assignment operators are unpacked, i.e. a+=b
    // becomes a=a+b; first for an Expression on the rhs
    template<class R>
    aReal& operator+=(const Expression<R>& rhs) {
      return *this = (*this + rhs);
    }
    template<class R>
    aReal& operator-=(const Expression<R>& rhs) {
      return *this = (*this - rhs);
    }
    template<class R>
    aReal& operator*=(const Expression<R>& rhs) {
      return *this = (*this * rhs);
    }
    template<class R>
    aReal& operator/=(const Expression<R>& rhs) {
      return *this = (*this / rhs);
    }

    // And likewise for a scalar on the rhs
    aReal& operator+=(const Real& rhs) {
      val_ += rhs;
      return *this;
    }
    aReal& operator-=(const Real& rhs) {
      val_ -= rhs;
      return *this;
    }
    aReal& operator*=(const Real& rhs) {
      return *this = (*this * rhs);
    }
    aReal& operator/=(const Real& rhs) {
      return *this = (*this / rhs);
    }

    // For modular codes, some modules may have an existing
    // Jacobian code and possibly be unsuitable for automatic
    // differentiation using Adept (e.g. because they are written in
    // Fortran).  In this case, we can use the following two functions
    // to "wrap" the non-Adept code.

    // Suppose the non-adept code uses the double values from n aReal
    // objects pointed to by "x" to produce a single double value
    // "y_val" (to be assigned to an aReal object "y"), plus a pointer
    // to an array of forward derivatives "dy_dx".  Firstly you should
    // assign the value using simply "y = y_val;", then call
    // "y.add_derivative_dependence(x, dy_dx, n);" to specify how y
    // depends on x. A fourth argument "multiplier_stride" may be used
    // to stride the indexing to the derivatives, in case they are
    // part of a matrix that is oriented in a different sense.
    void add_derivative_dependence(const aReal* rhs,
				   const Real* multiplier,
				   int n = 1, 
				   int multiplier_stride = 1) {
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
	// Check there is space in the operation stack for n entries
	ADEPT_ACTIVE_STACK->check_space(n);
#endif
	for (int i = 0; i < n; i++) {
	  Real mult = multiplier[i*multiplier_stride];
	  if (mult != 0.0) {
	    // For each non-zero multiplier, add a pseudo-operation to
	    // the operation stack
	    ADEPT_ACTIVE_STACK->push_rhs(mult,
					 rhs[i].gradient_offset());
	  }
	}
	ADEPT_ACTIVE_STACK->push_lhs(gradient_offset_);
#ifdef ADEPT_RECORDING_PAUSABLE
      }
#endif
    }

    // Suppose the non-Adept code uses double values from n aReal
    // objects pointed to by "x" and m aReal objects pointed to by "z"
    // to produce a single double value, plus pointers to arrays of
    // forward derivatives "dy_dx" and "dy_dz".  Firstly, as above,
    // you should assign the value using simply "y = y_val;", then
    // call "y.add_derivative_dependence(x, dy_dx, n);" to specify how
    // y depends on x.  To specify also how y depends on z, call
    // "y.append_derivative_dependence(z, dy_dz, n);".
    void append_derivative_dependence(const aReal* rhs,
				      const Real* multiplier,
				      int n = 1,
				      int multiplier_stride = 1) {
#ifdef ADEPT_RECORDING_PAUSABLE
      if (ADEPT_ACTIVE_STACK->is_recording()) {
#endif
#ifndef ADEPT_MANUAL_MEMORY_ALLOCATION
	// Check there is space in the operation stack for n entries
	ADEPT_ACTIVE_STACK->check_space(n);
#endif
	for (int i = 0; i < n; i ++) {
	  Real mult = multiplier[i*multiplier_stride];
	  if (mult != 0.0) {
	    // For each non-zero multiplier, add a pseudo-operation to
	    // the operation stack
	    ADEPT_ACTIVE_STACK->push_rhs(mult,
					 rhs[i].gradient_offset());
	  }
	}
	if (!(ADEPT_ACTIVE_STACK->update_lhs(gradient_offset_))) {
	  throw(wrong_gradient());
	}
#ifdef ADEPT_RECORDING_PAUSABLE
      }
#endif
    }
    // For only one independent variable on the rhs, these two
    // functions are convenient as they don't involve pointers
    void add_derivative_dependence(const aReal& rhs,
				   const Real& multiplier) {
      add_derivative_dependence(&rhs, &multiplier);
    }
    void append_derivative_dependence(const aReal& rhs,
				      const Real& multiplier) {
      append_derivative_dependence(&rhs, &multiplier);
    }
    
    // If an expression leads to calc_gradient being called on an
    // aReal object, we push the multiplier and the gradient offset on
    // to the operation stack (or 1.0 if no multiplier is specified
    void calc_gradient(Stack& stack) const {
      stack.push_rhs(1.0, gradient_offset_);
    }
    void calc_gradient(Stack& stack, const Real& multiplier) const {
      stack.push_rhs(multiplier, gradient_offset_);
    }
   
    // Get the actual value of this object; needed for fprintf calls,
    // for example, to get the underlying Real type out
    ADEPT_VALUE_RETURN_TYPE value() const {
      return val_; 
    }

    // Push the gradient on to the operation stack and return the
    // numerical value
    Real value_and_gradient(Stack& stack) const { 
      stack.push_rhs(1.0, gradient_offset_);
      return val_;
    };

    // Get the offset of the gradient information for this object
    const Offset& gradient_offset() const { return gradient_offset_; }
 
    // Set the value 
    void set_value(const Real& x) { val_ = x; }

    // Set the value of the gradient, for initializing an adjoint;
    // note that the value of the gradient is not held in the aReal
    // object but rather held by the stack
    void set_gradient(const Real& gradient) const {
      return ADEPT_ACTIVE_STACK->set_gradients(gradient_offset_,
					       gradient_offset_+1, 
					       &gradient);
    }

    // Get the value of the gradient, for extracting the adjoing after
    // calling reverse() on the stack
    void get_gradient(Real& gradient) const {
      return ADEPT_ACTIVE_STACK->get_gradients(gradient_offset_,
					       gradient_offset_+1, &gradient);
    }
    Real get_gradient() const {
      Real gradient = 0;
      ADEPT_ACTIVE_STACK->get_gradients(gradient_offset_,
					gradient_offset_+1, &gradient);
      return gradient;
    }
    
  private:
    // --- DATA SECTION ---
    Real val_;                     // The numerical value
    Offset gradient_offset_;       // Index to where the corresponding
				   // gradient will be held during the
				   // adjoint calculation
  }; // End of definition of aReal

#undef ADEPT_VALUE_RETURN_TYPE

  // ---------------------------------------------------------------------
  // SECTION 10: Helper functions
  // ---------------------------------------------------------------------

  // When we need source files that will be compiled twice, both
  // including automatic differentiation and without (the latter case
  // with aReal typedef'ed to double), it is useful to be able to
  // access the underlying value for calls to fprintf etc, so we
  // define the value function which does this for expressions, and in
  // the case without automatic differentiation (in which this header
  // file would not be included), the value function would be defined
  // for double arguments to simply return the argument.
  template<class A>
  inline Real value(const Expression<A>& x) { return x.value(); }
  
  // A way of setting the initial values of an array of n aReal
  // objects without the expense of placing them on the stack
  template<typename Type>
  inline
  void set_values(aReal* a, Offset n, const Type* data)
  {
    for (Offset i = 0; i < n; i++) {
      a[i].set_value(data[i]);
    }
  }

  // Extract the values of an array of n aReal objects
  template<typename Type>
  inline
  void get_values(const aReal* a, Offset n, Type* data)
  {
    for (Offset i = 0; i < n; i++) {
      data[i] = a[i].value();
    }
  }
  
  // Set the initial gradients of an array of n aReal objects; this
  // should be done after the algorithm has called and before the
  // Stack::forward or Stack::reverse functions are called
  template<typename Type>
  inline
  void set_gradients(aReal* a, Offset n, const Type* data)
  {
    for (Offset i = 0; i < n; i++) {
      a[i].set_gradient(data[i]);
    }
  }
  
  // Extract the gradients from an array of aReal objects after the
  // Stack::forward or Stack::reverse functions have been called
  template<typename Type>
  inline
  void get_gradients(const aReal* a, Offset n, Type* data)
  {
    for (Offset i = 0; i < n; i++) {
      a[i].get_gradient(data[i]);
    }
  }
  
  // If we send an aReal object to a stream it behaves just like a
  // double
  inline
  std::ostream&
  operator<<(std::ostream& os, const adept::aReal& x)
  {
    os << value(x);
    return os;
  }
  
  // Sending a Stack object to a stream reports information about the
  // stack
  inline
  std::ostream& operator<<(std::ostream& os, const adept::Stack& stack) {
    stack.print_status(os);
    return os;
  }

  // Memory to store statements and operations can be preallocated,
  // offering modest performance advantage if you define
  // ADEPT_MANUAL_MEMORY_ALLOCATION and know the maximum number of
  // statements and operations you will need. This version is useful
  // in functions that don't have visible access to the currently
  // active Adept stack.
  inline
  void preallocate_statements(Offset n) {
    ADEPT_ACTIVE_STACK->preallocate_statements(n);
  }
  inline
  void preallocate_operations(Offset n) {
    ADEPT_ACTIVE_STACK->preallocate_operations(n);
  }

  // Returns a pointer to the currently active stack (or 0 if there is none)
  inline
  Stack* active_stack() { return ADEPT_ACTIVE_STACK; }

  // Return the compiler used to compile the Adept library (e.g. "g++ 4.3.2")
  std::string compiler_version();

  // Return the compiler flags used when compiling the Adept library
  // (e.g. "-Wall -g -O3")
  std::string compiler_flags();
  
  // Return whether the active stack is stored in a global variable
  // (thread unsafe) rather than a thread-local global variable
  // (thread safe)
#ifdef ADEPT_STACK_THREAD_UNSAFE
  inline bool is_thread_unsafe() { return true; }
#else
  inline bool is_thread_unsafe() { return false; }
#endif 

  // Subsequent code should use adept::active_stack() rather than this
  // preprocessor macro
#undef ADEPT_ACTIVE_STACK
  
} // End of namespace adept


#else
// The following is executed only if
// ADEPT_NO_AUTOMATIC_DIFFERENTIATION is defined

namespace adept {
#ifdef ADEPT_FLOATING_POINT_TYPE
  typedef ADEPT_FLOATING_POINT_TYPE Real;
  typedef ADEPT_FLOATING_POINT_TYPE aReal;
#else
  typedef double Real;
  typedef double aReal;
#endif
}



#endif
// The following section is executed regardless of whether
// ADEPT_NO_AUTOMATIC_DIFFERENTIATION is defined

namespace adept {
  // Most people may want to use the less generic "adouble" for the
  // active type; this is what we called it in the paper
  typedef aReal adouble;
}



#endif
