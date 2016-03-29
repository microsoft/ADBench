/* adept.cpp -- Fast automatic differentiation with expression templates

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


#include <iostream>
#include <cstring> // For memcpy


#ifdef _OPENMP
#include <omp.h>
#endif

#include "adept.h"

#ifdef HAVE_CONFIG_H
// Obtain compiler (CXX) and compile flags (CXXFLAGS) from config.h
#include "config.h"
#endif


namespace adept {

  // Global pointers to the current thread, the second of which is
  // thread safe. The first is only used if ADEPT_STACK_THREAD_UNSAFE
  // is defined.
  ADEPT_THREAD_LOCAL Stack* _stack_current_thread = 0;
  Stack* _stack_current_thread_unsafe = 0;

  // Return the compiler used to compile the Adept library (e.g. "g++
  // [4.3.2]" or "Microsoft Visual C++ [1800]")
  std::string
  compiler_version()
  {
#ifdef CXX
    std::string cv = CXX; // Defined in config.h
#elif defined(_MSC_VER)
    std::string cv = "Microsoft Visual C++";
#else
    std::string cv = "unknown";
#endif

#ifdef __GNUC__

#define STRINGIFY3(A,B,C) STRINGIFY(A) "." STRINGIFY(B) "." STRINGIFY(C)
#define STRINGIFY(A) #A
    cv += " [" STRINGIFY3(__GNUC__,__GNUC_MINOR__,__GNUC_PATCHLEVEL__) "]";
#undef STRINGIFY
#undef STRINGIFY3

#elif defined(_MSC_VER)

#define STRINGIFY1(A) STRINGIFY(A)
#define STRINGIFY(A) #A
    cv += " [" STRINGIFY1(_MSC_VER) "]";
#undef STRINGIFY
#undef STRINGIFY1

#endif
    return cv;
  }

  // Return the compiler flags used when compiling the Adept library
  // (e.g. "-Wall -g -O3")
  std::string
  compiler_flags()
  {
#ifdef CXXFLAGS
    return CXXFLAGS; // Defined in config.h
#else
    return "unknown";
#endif
  }

  // MEMBER FUNCTIONS OF THE STACK CLASS

  // Destructor: frees dynamically allocated memory (if any)
  Stack::~Stack() {
    // If this is the currently active stack then set to NULL as
    // "this" is shortly to become invalid
    if (is_thread_unsafe_) {
      if (_stack_current_thread_unsafe == this) {
	_stack_current_thread_unsafe = 0; 
      }
    }
    else if (_stack_current_thread == this) {
      _stack_current_thread = 0; 
    }
#ifndef ADEPT_STACK_STORAGE_STL
    if (statement_) {
      delete[] statement_;
    }
    if (gradient_) {
      delete[] gradient_;
    }
    if (multiplier_) {
      delete[] multiplier_;
    }
    if (offset_) {
      delete[] offset_;
    }
#endif
  }
  
  // Make this stack "active" by copying its "this" pointer to a
  // global variable; this makes it the stack that aReal objects
  // subsequently interact with when being created and participating
  // in mathematical expressions
  void
  Stack::activate()
  {
    // Check that we don't already have an active stack in this thread
    if ((is_thread_unsafe_ && _stack_current_thread_unsafe 
	 && _stack_current_thread_unsafe != this)
	|| ((!is_thread_unsafe_) && _stack_current_thread
	    && _stack_current_thread != this)) {
      throw(stack_already_active());
    }
    else {
      if (!is_thread_unsafe_) {
	_stack_current_thread = this;
      }
      else {
	_stack_current_thread_unsafe = this;
      }
    }    
  }

  // This function is called by the constructor to initialize memory,
  // which can be grown subsequently
  void
  Stack::initialize(Offset n)
  {
#ifdef ADEPT_STACK_STORAGE_STL
    statement_.reserve(n);
    multiplier_.reserve(n);
    offset_.reserve(n);
#else
    multiplier_ = new Real[n];
    offset_ = new Offset[n];
    n_allocated_operations_ = n;
    statement_ = new Statement[n];
    n_allocated_statements_ = n;
#endif
    new_recording();
    //    statement_[0].offset = -1;
    //    statement_[0].end_plus_one = 0;
  }
 
#ifndef ADEPT_STACK_STORAGE_STL
  // Double the size of the operation stack, or grow it even more if
  // the requested minimum number of extra entries (min) is greater
  // than this would allow
  void
  Stack::grow_operation_stack(Offset min)
  {
    Offset new_size = 2*n_allocated_operations_;
    if (min > 0 && new_size < n_allocated_operations_+min) {
      new_size += min;
    }
    Real* new_multiplier = new Real[new_size];
    Offset* new_offset = new Offset[new_size];
    
    std::memcpy(new_multiplier, multiplier_, n_operations_*sizeof(Real));
    std::memcpy(new_offset, offset_, n_operations_*sizeof(Offset));
    
    delete[] multiplier_;
    delete[] offset_;
    
    multiplier_ = new_multiplier;
    offset_ = new_offset;
    
    n_allocated_operations_ = new_size;
  }

  // ... likewise for the statement stack
  void
  Stack::grow_statement_stack(Offset min)
  {
    Offset new_size = 2*n_allocated_statements_;
    if (min > 0 && new_size < n_allocated_statements_+min) {
      new_size += min;
    }
    Statement* new_statement = new Statement[new_size];
    std::memcpy(new_statement, statement_,
		n_statements_*sizeof(Statement));
    delete[] statement_;

    statement_ = new_statement;

    n_allocated_statements_ = new_size;
  }
#endif

  
  // Set the maximum number of threads to be used in Jacobian
  // calculations, if possible. A value of 1 indicates that OpenMP
  // will not be used, while a value of 0 indicates that the number
  // will match the number of available processors. Returns the
  // maximum that will be used, which will be 1 if the Adept library
  // was compiled without OpenMP support. Note that a value of 1 will
  // disable the use of OpenMP with Adept, so Adept will then use no
  // OpenMP directives or function calls. Note that if in your program
  // you use OpenMP with each thread performing automatic
  // differentiaion with its own independent Adept stack, then
  // typically only one OpenMP thread is available for each Jacobian
  // calculation, regardless of whether you call this function.
  int
  Stack::set_max_jacobian_threads(int n)
  {
#ifdef _OPENMP
    if (have_openmp_) {
      if (n == 1) {
	openmp_manually_disabled_ = true;
	return 1;
      }
      else if (n < 1) {
	openmp_manually_disabled_ = false;
	omp_set_num_threads(omp_get_num_procs());
	return omp_get_max_threads();
      }
      else {
	openmp_manually_disabled_ = false;
	omp_set_num_threads(n);
	return omp_get_max_threads();
      }
    }
#endif
    return 1;
  }


  // Return maximum number of OpenMP threads to be used in Jacobian
  // calculation
  int 
  Stack::max_jacobian_threads() const
  {
#ifdef _OPENMP
    if (have_openmp_) {
      if (openmp_manually_disabled_) {
	return 1;
      }
      else {
	return omp_get_max_threads();
      }
    }
#endif
    return 1;
  }


  // Perform to adjoint computation (reverse mode). It is assumed that
  // some gradients have been assigned already, otherwise the function
  // returns with an error.
  void
  Stack::compute_adjoint()
  {
    if (gradients_are_initialized()) {
      // Loop backwards through the derivative statements
      for (Offset ist = n_statements_-1; ist > 0; ist--) {
	const Statement& statement = statement_[ist];
	// We copy the RHS gradient (LHS in the original derivative
	// statement but swapped in the adjoint equivalent) to "a" in
	// case it appears on the LHS in any of the following statements
	Real a = gradient_[statement.offset];
	gradient_[statement.offset] = 0.0;
	// By only looping if a is non-zero we gain a significant speed-up
	if (a != 0.0) {
	  // Loop over operations
	  for (Offset i = statement_[ist-1].end_plus_one;
	       i < statement.end_plus_one; i++) {
	    gradient_[offset_[i]] += multiplier_[i]*a;
	  }
	}
      }
    }  
    else {
      throw(gradients_not_initialized());
    }  
  }


  // Perform tangent linear computation (forward mode). It is assumed
  // that some gradients have been assigned already, otherwise the
  // function returns with an error.
  void
  Stack::compute_tangent_linear()
  {
    if (gradients_are_initialized()) {
      // Loop forward through the statements
      for (Offset ist = 1; ist < n_statements_; ist++) {
	const Statement& statement = statement_[ist];
	// We copy the LHS to "a" in case it appears on the RHS in any
	// of the following statements
	Real a = 0.0;
	for (Offset i = statement_[ist-1].end_plus_one;
	     i < statement.end_plus_one; i++) {
	  a += multiplier_[i]*gradient_[offset_[i]];
	}
	gradient_[statement.offset] = a;
      }
    }
    else {
      throw(gradients_not_initialized());
    }
  }


  // Compute the Jacobian matrix; note that jacobian_out must be
  // allocated to be of size m*n, where m is the number of dependent
  // variables and n is the number of independents. The independents
  // and dependents must have already been identified with the
  // functions "independent" and "dependent", otherwise this function
  // will fail with FAILURE_XXDEPENDENT_NOT_IDENTIFIED. In the
  // resulting matrix, the "m" dimension of the matrix varies
  // fastest. This is implemented using a forward pass, appropriate
  // for m>=n.
  void
  Stack::jacobian_forward(Real* jacobian_out)
  {
    if (independent_offset_.empty() || dependent_offset_.empty()) {
      throw(dependents_or_independents_not_identified());
    }
#ifdef _OPENMP
    if (have_openmp_ 
	&& !openmp_manually_disabled_
	&& n_independent() > ADEPT_MULTIPASS_SIZE
	&& omp_get_max_threads() > 1) {
      // Call the parallel version
      jacobian_forward_openmp(jacobian_out);
      return;
    }
#endif

    gradient_multipass_.resize(max_gradient_);
    // For optimization reasons, we process a block of
    // ADEPT_MULTIPASS_SIZE columns of the Jacobian at once; calculate
    // how many blocks are needed and how many extras will remain
    Offset n_block = n_independent() / ADEPT_MULTIPASS_SIZE;
    Offset n_extra = n_independent() % ADEPT_MULTIPASS_SIZE;
    Offset i_independent = 0; // Index of first column in the block we
			      // are currently computing
    // Loop over blocks of ADEPT_MULTIPASS_SIZE columns
    for (Offset iblock = 0; iblock < n_block; iblock++) {
      // Set the initial gradients all to zero
      zero_gradient_multipass();
      // Each seed vector has one non-zero entry of 1.0
      for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	gradient_multipass_[independent_offset_[i_independent+i]][i] = 1.0;
      }
      // Loop forward through the derivative statements
      for (Offset ist = 1; ist < n_statements_; ist++) {
	const Statement& statement = statement_[ist];
	// We copy the LHS to "a" in case it appears on the RHS in any
	// of the following statements
	Block<ADEPT_MULTIPASS_SIZE,Real> a; // Initialized to zero
					    // automatically
	// Loop through operations
	for (Offset iop = statement_[ist-1].end_plus_one;
	     iop < statement.end_plus_one; iop++) {
	  if (multiplier_[iop] == 1.0) {
	    // Loop through columns within this block; we hope the
	    // compiler can optimize this loop
	    for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	      a[i] += gradient_multipass_[offset_[iop]][i];
	    }
	  }
	  else {
	    for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	      a[i] += multiplier_[iop]*gradient_multipass_[offset_[iop]][i];
	    }
	  }
	}
	// Copy the results
	for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	  gradient_multipass_[statement.offset][i] = a[i];
	}
      } // End of loop over statements
      // Copy the gradients corresponding to the dependent variables
      // into the Jacobian matrix
      for (Offset idep = 0; idep < n_dependent(); idep++) {
	for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	  jacobian_out[(i_independent+i)*n_dependent()+idep] 
	    = gradient_multipass_[dependent_offset_[idep]][i];
	}
      }
      i_independent += ADEPT_MULTIPASS_SIZE;
    } // End of loop over blocks
    
    // Now do the same but for the remaining few columns in the matrix
    if (n_extra > 0) {
      zero_gradient_multipass();
      for (Offset i = 0; i < n_extra; i++) {
	gradient_multipass_[independent_offset_[i_independent+i]][i] = 1.0;
      }
      for (Offset ist = 1; ist < n_statements_; ist++) {
	const Statement& statement = statement_[ist];
	Block<ADEPT_MULTIPASS_SIZE,Real> a;
	for (Offset iop = statement_[ist-1].end_plus_one;
	     iop < statement.end_plus_one; iop++) {
	  if (multiplier_[iop] == 1.0) {
	    for (Offset i = 0; i < n_extra; i++) {
	      a[i] += gradient_multipass_[offset_[iop]][i];
	    }
	  }
	  else {
	    for (Offset i = 0; i < n_extra; i++) {
	      a[i] += multiplier_[iop]*gradient_multipass_[offset_[iop]][i];
	    }
	  }
	}
	for (Offset i = 0; i < n_extra; i++) {
	  gradient_multipass_[statement.offset][i] = a[i];
	}
      }
      for (Offset idep = 0; idep < n_dependent(); idep++) {
	for (Offset i = 0; i < n_extra; i++) {
	  jacobian_out[(i_independent+i)*n_dependent()+idep] 
	    = gradient_multipass_[dependent_offset_[idep]][i];
	}
      }
    }
  }


  // Compute the Jacobian matrix; note that jacobian_out must be
  // allocated to be of size m*n, where m is the number of dependent
  // variables and n is the number of independents. The independents
  // and dependents must have already been identified with the
  // functions "independent" and "dependent", otherwise this function
  // will fail with FAILURE_XXDEPENDENT_NOT_IDENTIFIED. In the
  // resulting matrix, the "m" dimension of the matrix varies
  // fastest. This is implemented using a reverse pass, appropriate
  // for m<n.
  void
  Stack::jacobian_reverse(Real* jacobian_out)
  {
    if (independent_offset_.empty() || dependent_offset_.empty()) {
      throw(dependents_or_independents_not_identified());
    }
#ifdef _OPENMP
    if (have_openmp_ 
	&& !openmp_manually_disabled_
	&& n_dependent() > ADEPT_MULTIPASS_SIZE
	&& omp_get_max_threads() > 1) {
      // Call the parallel version
      jacobian_reverse_openmp(jacobian_out);
      return;
    }
#endif

    gradient_multipass_.resize(max_gradient_);
    // For optimization reasons, we process a block of
    // ADEPT_MULTIPASS_SIZE rows of the Jacobian at once; calculate
    // how many blocks are needed and how many extras will remain
    Offset n_block = n_dependent() / ADEPT_MULTIPASS_SIZE;
    Offset n_extra = n_dependent() % ADEPT_MULTIPASS_SIZE;
    Offset i_dependent = 0; // Index of first row in the block we are
			    // currently computing
    // Loop over the of ADEPT_MULTIPASS_SIZE rows
    for (Offset iblock = 0; iblock < n_block; iblock++) {
      // Set the initial gradients all to zero
      zero_gradient_multipass();
      // Each seed vector has one non-zero entry of 1.0
      for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	gradient_multipass_[dependent_offset_[i_dependent+i]][i] = 1.0;
      }
      // Loop backward through the derivative statements
      for (Offset ist = n_statements_-1; ist > 0; ist--) {
	const Statement& statement = statement_[ist];
	// We copy the RHS to "a" in case it appears on the LHS in any
	// of the following statements
	Real a[ADEPT_MULTIPASS_SIZE];
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	// For large blocks, we only process the ones where a[i] is
	// non-zero
	Offset i_non_zero[ADEPT_MULTIPASS_SIZE];
#endif
	Offset n_non_zero = 0;
	for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	  a[i] = gradient_multipass_[statement.offset][i];
	  gradient_multipass_[statement.offset][i] = 0.0;
	  if (a[i] != 0.0) {
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	    i_non_zero[n_non_zero++] = i;
#else
	    n_non_zero = 1;
#endif
	  }
	}
	// Only do anything for this statement if any of the a values
	// are non-zero
	if (n_non_zero) {
	  // Loop through the operations
	  for (Offset iop = statement_[ist-1].end_plus_one;
	       iop < statement.end_plus_one; iop++) {
	    // Try to minimize pointer dereferencing by making local
	    // copies
	    register Real multiplier = multiplier_[iop];
	    register Real* __restrict gradient_multipass 
	      = &(gradient_multipass_[offset_[iop]][0]);
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	    // For large blocks, loop over only the indices
	    // corresponding to non-zero a
	    for (Offset i = 0; i < n_non_zero; i++) {
	      gradient_multipass[i_non_zero[i]] += multiplier*a[i_non_zero[i]];
	    }
#else
	    // For small blocks, do all indices
	    for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	      gradient_multipass[i] += multiplier*a[i];
	    }
#endif
	  }
	}
      } // End of loop over statement
      // Copy the gradients corresponding to the independent variables
      // into the Jacobian matrix
      for (Offset iindep = 0; iindep < n_independent(); iindep++) {
	for (Offset i = 0; i < ADEPT_MULTIPASS_SIZE; i++) {
	  jacobian_out[iindep*n_dependent()+i_dependent+i] 
	    = gradient_multipass_[independent_offset_[iindep]][i];
	}
      }
      i_dependent += ADEPT_MULTIPASS_SIZE;
    } // End of loop over blocks
    
    // Now do the same but for the remaining few rows in the matrix
    if (n_extra > 0) {
      zero_gradient_multipass();
      for (Offset i = 0; i < n_extra; i++) {
	gradient_multipass_[dependent_offset_[i_dependent+i]][i] = 1.0;
      }
      for (Offset ist = n_statements_-1; ist > 0; ist--) {
	const Statement& statement = statement_[ist];
	Real a[ADEPT_MULTIPASS_SIZE];
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	Offset i_non_zero[ADEPT_MULTIPASS_SIZE];
#endif
	Offset n_non_zero = 0;
	for (Offset i = 0; i < n_extra; i++) {
	  a[i] = gradient_multipass_[statement.offset][i];
	  gradient_multipass_[statement.offset][i] = 0.0;
	  if (a[i] != 0.0) {
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	    i_non_zero[n_non_zero++] = i;
#else
	    n_non_zero = 1;
#endif
	  }
	}
	if (n_non_zero) {
	  for (Offset iop = statement_[ist-1].end_plus_one;
	       iop < statement.end_plus_one; iop++) {
	    register Real multiplier = multiplier_[iop];
	    register Real* __restrict gradient_multipass 
	      = &(gradient_multipass_[offset_[iop]][0]);
#if ADEPT_MULTIPASS_SIZE > ADEPT_MULTIPASS_SIZE_ZERO_CHECK
	    for (Offset i = 0; i < n_non_zero; i++) {
	      gradient_multipass[i_non_zero[i]] += multiplier*a[i_non_zero[i]];
	    }
#else
	    for (Offset i = 0; i < n_extra; i++) {
	      gradient_multipass[i] += multiplier*a[i];
	    }
#endif
	  }
	}
      }
      for (Offset iindep = 0; iindep < n_independent(); iindep++) {
	for (Offset i = 0; i < n_extra; i++) {
	  jacobian_out[iindep*n_dependent()+i_dependent+i] 
	    = gradient_multipass_[independent_offset_[iindep]][i];
	}
      }
    }
  }
  

  // If an aReal object is deleted, its gradient_offset is
  // unregistered from the stack.  If this is at the top of the stack
  // then this is easy and is done inline; this is the usual case
  // since C++ trys to deallocate automatic objects in the reverse
  // order to that in which they were allocated.  If it is not at the
  // top of the stack then a non-inline function is called to ensure
  // that the gap list is adjusted correctly.
  void
  Stack::unregister_gradient_not_top(const Offset& gradient_offset)
  {
    enum {
      ADDED_AT_BASE,
      ADDED_AT_TOP,
      NEW_GAP,
      NOT_FOUND
    } status = NOT_FOUND;
    // First try to find if the unregistered element is at the
    // start or end of an existing gap
    if (!gap_list_.empty() && most_recent_gap_ != gap_list_.end()) {
      // We have a "most recent" gap - check whether the gradient
      // to be unregistered is here
      Gap& current_gap = *most_recent_gap_;
      if (gradient_offset == current_gap.start - 1) {
	current_gap.start--;
	status = ADDED_AT_BASE;
      }
      else if (gradient_offset == current_gap.end + 1) {
	current_gap.end++;
	status = ADDED_AT_TOP;
      }
      // Should we check for erroneous removal from middle of gap?
    }
    if (status == NOT_FOUND) {
      // Search other gaps
      for (GapListIterator it = gap_list_.begin();
	   it != gap_list_.end(); it++) {
	if (gradient_offset <= it->end + 1) {
	  // Gradient to unregister is either within the gap
	  // referenced by iterator "it", or it is between "it"
	  // and the previous gap in the list
	  if (gradient_offset == it->start - 1) {
	    status = ADDED_AT_BASE;
	    it->start--;
	    most_recent_gap_ = it;
	  }
	  else if (gradient_offset == it->end + 1) {
	    status = ADDED_AT_TOP;
	    it->end++;
	    most_recent_gap_ = it;
	  }
	  else {
	    // Insert a new gap of width 1; note that list::insert
	    // inserts *before* the specified location
	    most_recent_gap_
	      = gap_list_.insert(it, Gap(gradient_offset));
	    status = NEW_GAP;
	  }
	  break;
	}
      }
      if (status == NOT_FOUND) {
	gap_list_.push_back(Gap(gradient_offset));
	most_recent_gap_ = gap_list_.end();
	most_recent_gap_--;
      }
    }
    // Finally check if gaps have merged
    if (status == ADDED_AT_BASE
	&& most_recent_gap_ != gap_list_.begin()) {
      // Check whether the gap has merged with the next one
      GapListIterator it = most_recent_gap_;
      it--;
      if (it->end == most_recent_gap_->start - 1) {
	// Merge two gaps
	most_recent_gap_->start = it->start;
	gap_list_.erase(it);
      }
    }
    else if (status == ADDED_AT_TOP) {
      GapListIterator it = most_recent_gap_;
      it++;
      if (it != gap_list_.end()
	  && it->start == most_recent_gap_->end + 1) {
	// Merge two gaps
	most_recent_gap_->end = it->end;
	gap_list_.erase(it);
      }
    }
  }	
  
  
  // Compute the Jacobian matrix; note that jacobian_out must be
  // allocated to be of size m*n, where m is the number of dependent
  // variables and n is the number of independents. In the resulting
  // matrix, the "m" dimension of the matrix varies fastest. This is
  // implemented by calling one of jacobian_forward and
  // jacobian_reverse, whichever would be faster.
  void
  Stack::jacobian(Real* jacobian_out)
  {
    if (n_independent() <= n_dependent()) {
      jacobian_forward(jacobian_out);
    }
    else {
      jacobian_reverse(jacobian_out);
    }
  }
  
  // Print each derivative statement to the specified stream (standard
  // output if omitted)
  void
  Stack::print_statements(std::ostream& os) const
  {
    for (Offset ist = 1; ist < n_statements_; ist++) {
      const Statement& statement = statement_[ist];
      os << ist
		<< ": d[" << statement.offset
		<< "] = ";
      
      if (statement_[ist-1].end_plus_one == statement_[ist].end_plus_one) {
	os << "0\n";
      }
      else {    
	for (Offset i = statement_[ist-1].end_plus_one;
	     i < statement.end_plus_one; i++) {
	  os << " + " << multiplier_[i] << "*d[" << offset_[i] << "]";
	}
	os << "\n";
      }
    }
  }
  
  // Print the current gradient list to the specified stream (standard
  // output if omitted)
  bool
  Stack::print_gradients(std::ostream& os) const
  {
    if (gradients_are_initialized()) {
      for (Offset i = 0; i < max_gradient_; i++) {
	if (i%10 == 0) {
	  if (i != 0) {
	    os << "\n";
	  }
	  os << i << ":";
	}
	os << " " << gradient_[i];
      }
      os << "\n";
      return true;
    }
    else {
      os << "No gradients initialized\n";
      return false;
    }
  }

  // Print the list of gaps in the gradient list to the specified
  // stream (standard output if omitted)
  void
  Stack::print_gaps(std::ostream& os) const
  {
    for (GapList::const_iterator it = gap_list_.begin();
	 it != gap_list_.end(); it++) {
      os << it->start << "-" << it->end << " ";
    }
  }


#ifndef ADEPT_STACK_STORAGE_STL
  // Initialize the vector of gradients ready for the adjoint
  // calculation
  void
  Stack::initialize_gradients()
  {
    if (max_gradient_ > 0) {
      if (n_allocated_gradients_ < max_gradient_) {
	if (gradient_) {
	  delete[] gradient_;
	}
	gradient_ = new Real[max_gradient_];
	n_allocated_gradients_ = max_gradient_;
      }
      for (Offset i = 0; i < max_gradient_; i++) {
	gradient_[i] = 0.0;
      }
    }
    gradients_initialized_ = true;
  }
#else
  void
  Stack::initialize_gradients()
  {
    gradient_.resize(max_gradient_+10, 0.0);
    gradients_initialized_ = true;
  }
#endif

  // Report information about the stack to the specified stream, or
  // standard output if omitted; note that this is synonymous with
  // sending the Stack object to a stream using the "<<" operator.
  void
  Stack::print_status(std::ostream& os) const
  {
    os << "Automatic Differentiation Stack (address " << this << "):\n";
    if ((!is_thread_unsafe_) && _stack_current_thread == this) {
      os << "   Currently attached - thread safe\n";
    }
    else if (is_thread_unsafe_ && _stack_current_thread_unsafe == this) {
      os << "   Currently attached - thread unsafe\n";
    }
    else {
      os << "   Currently detached\n";
    }
    os << "   Recording status:\n";
    // Account for the null statement at the start by subtracting one
    os << "      " << n_statements()-1 << " statements (" 
       << n_allocated_statements() << " allocated)";
    os << " and " << n_operations() << " operations (" 
       << n_allocated_operations() << " allocated)\n";
    os << "      " << n_gradients_registered() << " gradients currently registered ";
    os << "and a total of " << max_gradients() << " needed (current index "
       << i_gradient() << ")\n";
    if (gap_list_.empty()) {
      os << "      Gradient list has no gaps\n";
    }
    else {
      os << "      Gradient list has " << gap_list_.size() << " gaps (";
      print_gaps(os);
      os << ")\n";
    }
    os << "   Computation status:\n";
    if (gradients_are_initialized()) {
      os << "      " << max_gradients() << " gradients assigned (" 
	 << n_allocated_gradients() << " allocated)\n";
    }
    else {
      os << "      0 gradients assigned (" << n_allocated_gradients()
	 << " allocated)\n";
    }
    os << "      Jacobian size: " << n_dependents() << "x" << n_independents() << "\n";
#ifdef _OPENMP
    if (have_openmp_) {
      if (openmp_manually_disabled_) {
	os << "      Parallel Jacobian calculation manually disabled\n";
      }
      else {
	os << "      Parallel Jacobian calculation can use up to "
	   << omp_get_max_threads() << " threads\n";
	os << "      Each thread treats " << ADEPT_MULTIPASS_SIZE 
	   << " (in)dependent variables\n";
      }
    }
    else {
#endif
      os << "      Parallel Jacobian calculation not available\n";
#ifdef _OPENMP
    }
#endif
  }
} // End namespace adept

