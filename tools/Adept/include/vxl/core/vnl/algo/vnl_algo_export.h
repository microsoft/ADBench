
#ifndef VNL_ALGO_EXPORT_H
#define VNL_ALGO_EXPORT_H

#ifdef VNL_ALGO_STATIC_DEFINE
#  define VNL_ALGO_EXPORT
#  define VNL_ALGO_NO_EXPORT
#else
#  ifndef VNL_ALGO_EXPORT
#    ifdef vnl_algo_EXPORTS
        /* We are building this library */
#      define VNL_ALGO_EXPORT 
#    else
        /* We are using this library */
#      define VNL_ALGO_EXPORT 
#    endif
#  endif

#  ifndef VNL_ALGO_NO_EXPORT
#    define VNL_ALGO_NO_EXPORT 
#  endif
#endif

#ifndef VNL_ALGO_DEPRECATED
#  define VNL_ALGO_DEPRECATED __declspec(deprecated)
#endif

#ifndef VNL_ALGO_DEPRECATED_EXPORT
#  define VNL_ALGO_DEPRECATED_EXPORT VNL_ALGO_EXPORT VNL_ALGO_DEPRECATED
#endif

#ifndef VNL_ALGO_DEPRECATED_NO_EXPORT
#  define VNL_ALGO_DEPRECATED_NO_EXPORT VNL_ALGO_NO_EXPORT VNL_ALGO_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define VNL_ALGO_NO_DEPRECATED
#endif

#endif
