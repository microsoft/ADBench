// ManualGMM.h - Contains declarations of GMM tester functions
#pragma once

// By default, the New Project template for a DLL adds <em>PROJECTNAME</em>_EXPORTS
// to the defined preprocessor macros for the DLL project:
#ifdef MANUALGMM_EXPORTS
#define MANUALGMM_API __declspec(dllexport)
#else
#define MANUALGMM_API __declspec(dllimport)
#endif

// This function must be called before any other function.
extern "C" MANUALGMM_API void prepare(
	int& d, int& k, int& n,
	vector<double> alphas, vector<double>means,
	vector<double> icf, vector<double> x,
	Wishart wishart,
	int nruns_f, int nruns_J,
	double time_limit);

// perform AD
extern "C" MANUALGMM_API void performAD(int times);

// 
extern "C" MANUALGMM_API void output(); //maybe not void