#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([adept], [1.1], [r.j.hogan@reading.ac.uk])

AC_LANG([C++])

AC_CONFIG_SRCDIR([adept/adept.cpp])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([-Wall -Wno-error])

# Checks for programs.
AC_PROG_CXX
AC_PROG_MAKE_SET
AC_PROG_LIBTOOL

# Checks for libraries.
AC_CHECK_LIB([m],[cos])
AC_CHECK_LIB([gsl],[gsl_multimin_fdfminimizer_alloc])
AC_CHECK_LIB([adolc],[tapestats])

# Check for OpenMP
AC_OPENMP
AC_SUBST(AM_CXXFLAGS,"$OPENMP_CXXFLAGS")

# Test program to see if Sacado is working
ac_have_sacado=no
save_LIBS=$LIBS
LIBS="$LIBS -lsacado -lteuchos"
AC_MSG_CHECKING([whether Sacado is installed])
AC_TRY_LINK([#include <Sacado.hpp>],
[Sacado::ELRFad::DFad<double> v = 1.0; return 0;],
[ac_have_sacado=yes
AC_MSG_RESULT(yes)
AC_DEFINE([HAVE_SACADO],1,[Is the Sacado library working?])],
[LIBS=$save_LIBS
AC_MSG_RESULT(no)])

# Checks for header files.
AC_CHECK_HEADERS([sys/time.h])
AC_CHECK_HEADERS([cppad/cppad.hpp])
AC_CHECK_HEADERS([adolc/adolc.h])

if test "$ac_cv_header_cppad_cppad_hpp" = yes
then
   AC_DEFINE([NDEBUG],1,[If CppAD is being used by the benchmarking program then it is much faster with debugging disabled])
fi

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T

# Checks for library functions.
AC_CHECK_FUNCS([gettimeofday pow sqrt])

AC_CONFIG_FILES([Makefile makefile_include adept/Makefile include/Makefile benchmark/Makefile])

AC_MSG_NOTICE([********************* Summary **************************************])
AC_MSG_NOTICE([Compiling with: $CXX $CPPFLAGS $CXXFLAGS $OPENMP_CXXFLAGS])
AC_MSG_NOTICE([Linker options: $LDFLAGS $LIBS $OPENMP_CXXFLAGS])
AC_MSG_NOTICE([Typing "make; make install" will install $includedir/adept.h])
AC_MSG_NOTICE([and the static and shared libraries as $libdir/libadept.*])
AC_MSG_NOTICE([********************* Example programs *****************************])

ac_warn_given=no
if test "$ac_cv_lib_gsl_gsl_multimin_fdfminimizer_alloc" = no
then
	AC_MSG_NOTICE([GNU Scientific Library (GSL) not found; Adept will compile all the])
	AC_MSG_NOTICE([example programs except test/test_gsl_interface.])
	ac_warn_given=yes
else
	AC_MSG_NOTICE([GNU Scientific Library (GSL) found; Adept will compile all the])
	AC_MSG_NOTICE([example programs.])
fi
AC_SUBST([USE_GSL], ["$ac_cv_lib_gsl_gsl_multimin_fdfminimizer_alloc"])


AC_MSG_NOTICE([********************* Benchmark program ****************************])
AC_MSG_NOTICE([The benchmarking program, "benchmark/advection_benchmark", will be])
AC_MSG_NOTICE([compiled with support for these automatic differentiation libraries:])
AC_MSG_NOTICE([   Adept: yes])

if test "$ac_cv_lib_adolc_tapestats" = yes -a "$ac_cv_header_adolc_adolc_h" = yes
then
   	AC_MSG_NOTICE([   ADOLC: yes])
else
	AC_MSG_NOTICE([   ADOLC: no])
	ac_warn_given=yes
fi

if test "$ac_cv_header_cppad_cppad_hpp" = yes
then
   	AC_MSG_NOTICE([   CppAD: yes])
else
	AC_MSG_NOTICE([   CppAD: no])
	ac_warn_given=yes
fi

if test "$ac_have_sacado" = no
then
	AC_MSG_NOTICE([   Sacado: no])
	ac_warn_given=yes
else
	AC_MSG_NOTICE([   Sacado: yes])
fi

AC_MSG_NOTICE([********************* Top tips *************************************])
AC_MSG_NOTICE([To use a higher than default optimization level, call this script])
AC_MSG_NOTICE([with something like:])
AC_MSG_NOTICE([  ./configure "CXXFLAGS=-g -O3"])
if test "$ac_warn_given" = yes
then
	AC_MSG_NOTICE([If you have some of the missing libraries, specify their location])
	AC_MSG_NOTICE([by calling this script with something like:])
	AC_MSG_NOTICE([  ./configure CPPFLAGS=-I/home/user/include LDFLAGS=-L/home/user/lib])
fi
AC_MSG_NOTICE([********************************************************************])

AC_DEFINE_UNQUOTED([CXX],["$CXX"],[C++ compiler])
AC_DEFINE_UNQUOTED([CXXFLAGS],["$CXXFLAGS"],[Flags passed to C++ compiler])

AH_BOTTOM([/* Use ADOLC only if both the library and the header files are available */
#if defined( HAVE_LIBADOLC ) && defined( HAVE_ADOLC_ADOLC_H )
#define HAVE_ADOLC 1
#endif])
AH_BOTTOM([/* Use CPPAD if the header files are available */
#if defined( HAVE_CPPAD_CPPAD_HPP )
#define HAVE_CPPAD 1
#endif])


AC_OUTPUT
