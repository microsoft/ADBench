/* advection_schemes.h - Two test advection algorithms from the Adept paper

  Copyright (C) 2014 The University of Reading

  Copying and distribution of this file, with or without modification,
  are permitted in any medium without royalty provided the copyright
  notice and this notice are preserved.  This file is offered as-is,
  without any warranty.
*/

// Use templates so that these functions can be easily compiled with
// different automatic differentiation tools in order that the
// performance of these tools can be compared.

#ifndef ADVECTION_SCHEMES_H
#define ADVECTION_SCHEMES_H 1

#include <cmath>

// Use a fixed problem size
#include "nx.h"

// Lax-Wendroff scheme applied to linear advection
template <class adouble>
void lax_wendroff(int nt, double c, const adouble q_init[NX], adouble q[NX]) {
  adouble flux[NX-1];                        // Fluxes between boxes
  for (int i=0; i<NX; i++) q[i] = q_init[i]; // Initialize q 
  for (int j=0; j<nt; j++) {                 // Main loop in time
    for (int i=0; i<NX-1; i++) flux[i] = 0.5*c*(q[i]+q[i+1]+c*(q[i]-q[i+1]));
    for (int i=1; i<NX-1; i++) q[i] += flux[i-1]-flux[i];
    q[0] = q[NX-2]; q[NX-1] = q[1];          // Treat boundary conditions
  }
}

// Toon advection scheme applied to linear advection
template <class adouble>
void toon(int nt, double c, const adouble q_init[NX], adouble q[NX]) {
  adouble flux[NX-1];                        // Fluxes between boxes
  for (int i=0; i<NX; i++) q[i] = q_init[i]; // Initialize q
  for (int j=0; j<nt; j++) {                 // Main loop in time
    for (int i=0; i<NX-1; i++) {
      // Need to check if the difference between adjacent points is
      // not too small or we end up with close to 0/0.  Unfortunately
      // the "fabs" function is not always available in CppAD, hence
      // the following.
      adouble bigdiff = (q[i]-q[i+1])*1.0e6;
      if (bigdiff > q[i] || bigdiff < -q[i]) {
	flux[i] = (exp(c*log(q[i]/q[i+1]))-1.0)
	  * q[i]*q[i+1] / (q[i]-q[i+1]);
      }
      else {
	flux[i] = c*q[i]; // Upwind scheme
      }
    }
    for (int i=1; i<NX-1; i++) q[i] += flux[i-1]-flux[i];
    q[0] = q[NX-2]; q[NX-1] = q[1];          // Treat boundary conditions
  }
}

#endif
