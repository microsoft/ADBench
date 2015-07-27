
#ifndef ADSTACK_LOADED
#define ADSTACK_LOADED 1

extern void pushcharacterarray(char *x, int n) ;
extern void popcharacterarray(char *x, int n) ;
extern void lookcharacterarray(char *x, int n) ;

extern void pushbooleanarray(char *x, int n) ;
extern void popbooleanarray(char *x, int n) ;
extern void lookbooleanarray(char *x, int n) ;

extern void pushinteger4array(int *x, int n) ;
extern void popinteger4array(int *x, int n) ;
extern void lookinteger4array(int *x, int n) ;

extern void pushinteger8array(long int *x, int n) ;
extern void popinteger8array(long int *x, int n) ;
extern void lookinteger8array(long int *x, int n) ;

extern void pushinteger16array(long long int *x, int n) ;
extern void popinteger16array(long long int *x, int n) ;
extern void lookinteger16array(long long int *x, int n) ;

extern void pushreal4array(float *x, int n) ;
extern void popreal4array(float *x, int n) ;
extern void lookreal4array(float *x, int n) ;

extern void pushreal8array(double *x, int n) ;
extern void popreal8array(double *x, int n) ;
extern void lookreal8array(double *x, int n) ;

extern void pushreal16array(void *x, int n) ;
extern void popreal16array(void *x, int n) ;
extern void lookreal16array(void *x, int n) ;

extern void pushreal32array(void *x, int n) ;
extern void popreal32array(void *x, int n) ;
extern void lookreal32array(void *x, int n) ;

extern void pushcomplex4array(void *x, int n) ;
extern void popcomplex4array(void *x, int n) ;
extern void lookcomplex4array(void *x, int n) ;

extern void pushcomplex8array(void *x, int n) ;
extern void popcomplex8array(void *x, int n) ;
extern void lookcomplex8array(void *x, int n) ;

extern void pushcomplex16array(void *x, int n) ;
extern void popcomplex16array(void *x, int n) ;
extern void lookcomplex16array(void *x, int n) ;

extern void pushcomplex32array(void *x, int n) ;
extern void popcomplex32array(void *x, int n) ;
extern void lookcomplex32array(void *x, int n) ;

extern void pushpointer4array(void *x, int n) ;
extern void poppointer4array(void *x, int n) ;
extern void lookpointer4array(void *x, int n) ;

extern void pushpointer8array(void *x, int n) ;
extern void poppointer8array(void *x, int n) ;
extern void lookpointer8array(void *x, int n) ;

extern void pushNarray(void *x, unsigned int nbChars) ;
extern void popNarray(void *x, unsigned int nbChars) ;
extern void lookNarray(void *x, unsigned int nbChars) ;

extern void resetadlookstack_() ;

extern void printbigbytes(long int nbblocks, long int blocksz, long int nbunits) ;

extern void printctraffic_() ;

extern void printtopplace_() ;

extern void printstackmax_() ;

extern void printlookingplace_() ;

extern void showrecentcstack_() ;

extern void getbigcsizes_(int *nbblocks, int *remainder, int *nbblockslook, int *lookremainder) ;

#endif
