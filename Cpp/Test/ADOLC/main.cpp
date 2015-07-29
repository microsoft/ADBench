#include <iostream>
#include <string>
#include <fstream>
#include <chrono>

#define SPARSE
#include "adolc\adolc.h"
#include "../utils.h"
#include "../defs.h"
#include "gmm.h"
#include "ba.h"

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

double compute_gmm_J(int nruns,
	int d, int k, int n, double *alphas, 
	double *means, double *icf, double *x, 
	Wishart wishart, double& err, double **J)
{
	high_resolution_clock::time_point start, end;
	start = high_resolution_clock::now();

	int tapeTag = 1;
	int icf_sz = d*(d + 1) / 2;
	int Jrows = 1;
	int Jcols = (k*(d + 1)*(d + 2)) / 2;
	adouble *aalphas, *ameans, *aicf, aerr;

	// Record on a tape
	trace_on(tapeTag);

	aalphas = new adouble[k];
	for (int i = 0; i < k; i++)
	{
		aalphas[i] <<= alphas[i];
	}

	ameans = new adouble[d*k];
	for (int i = 0; i < d*k; i++)
	{
		ameans[i] <<= means[i];
	}

	aicf = new adouble[icf_sz*k];
	for (int i = 0; i < icf_sz*k; i++)
	{
		aicf[i] <<= icf[i];
	}

	gmm_objective(d, k, n, aalphas, ameans, 
		aicf, x, wishart, &aerr);

	aerr >>= err;

	trace_off();

	delete[] aalphas;
	delete[] ameans;
	delete[] aicf;

	// Compute J
	double *in = new double[Jcols];
	memcpy(in, alphas, k*sizeof(double));
	int off = k;
	memcpy(in + off, means, d*k*sizeof(double));
	off += d*k;
	memcpy(in + off, icf, icf_sz*k*sizeof(double));

	for (int i = 0; i < nruns; i++)
	{
		gradient(tapeTag, Jcols, in, J[0]);

		//int keepValues = 1;
		//double errd = 1;
		//zos_forward(tapeTag, Jrows, Jcols, keepValues, in, &err);
		//fos_reverse(tapeTag, Jrows, Jcols, &errd, J[0]);
	}

	end = high_resolution_clock::now();
	return duration_cast<duration<double>>(end - start).count() / nruns;
}

void test_gmm(char *argv[])
{
	int d, k, n;
	double *alphas, *means, *icf, *x;
	double err;
	Wishart wishart;

	// Read instance
	string fn(argv[1]);
	read_gmm_instance(fn + ".txt", d, k, n, 
		alphas, means, icf, x, wishart);

	int icf_sz = d*(d + 1) / 2;
	int Jrows = 1;
	int Jcols = (k*(d + 1)*(d + 2)) / 2;

	double **J = new double*[Jrows];
	for (int i = 0; i < Jrows; i++)
	{
		J[i] = new double[Jcols];
	}

	// Test
	high_resolution_clock::time_point start, end;
	double tf, tJ;
	int nruns = 100;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		gmm_objective(d, k, n, alphas, means, 
			icf, x, wishart, &err);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;

	tJ = compute_gmm_J(nruns, d, k, n, alphas,
		means, icf, x, wishart, err, J);

	write_J(fn + "J_ADOLC.txt", Jrows, Jcols, J);
	write_times(tf, tJ);

	for (int i = 0; i < Jrows; i++)
	{
		delete[] J[i];
	}
	delete[] J;
	delete[] alphas;
	delete[] means;
	delete[] icf;
}

void read_ba_instance(const string& fn, int& n, int& m, int& p,
	double*& cams, double*& X, int*& obs, double*& feats)
{
	std::ifstream in(fn);

	in >> n >> m >> p;
	int nCamParams = 11;

	cams = new double[nCamParams * n];
	X = new double[3 * m];
	obs = new int[2 * p];
	feats = new double[2 * p];

	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < nCamParams; j++)
		{
			in >> cams[i * nCamParams + j];
		}
	}

	for (int i = 0; i < m; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			in >> X[i * 3 + j];
		}
	}

	for (int i = 0; i < p; i++)
	{
		in >> obs[i * 2 + 0] >> obs[i * 2 + 1];
	}

	for (int i = 0; i < p; i++)
	{
		in >> feats[i * 2 + 0] >> feats[i * 2 + 1];
	}

	in.close();
}

double compute_ba_J(bool doRowCompression,int nruns, int n, int m, int p, 
	double *cams, double *X, int *obs, double *feats, 
	double *err, double **J)
{
	high_resolution_clock::time_point start, end;
	start = high_resolution_clock::now();

	int tapeTag = 1;
	int nCamParams = 11;
	int Jcols = nCamParams * n + 3 * m;
	int Jrows = p;

	adouble *acams, *aX, *aerr;

	aerr = new adouble[p];

	// Record on a tape
	trace_on(tapeTag);

	acams = new adouble[nCamParams*n];
	for (int i = 0; i < nCamParams*n; i++)
	{
		acams[i] <<= cams[i];
	}

	aX = new adouble[3*m];
	for (int i = 0; i < 3*m; i++)
	{
		aX[i] <<= X[i];
	}

	ba(n, m, p, acams, aX, obs, feats, aerr);

	for (int i = 0; i < p; i++)
	{
		aerr[i] >>= err[i];
	}

	trace_off();

	delete[] acams;
	delete[] aX;
	delete[] aerr;

	// Compute J
	double *in = new double[Jcols];
	memcpy(in, cams, nCamParams*n*sizeof(double));
	int off = nCamParams*n;
	memcpy(in + off, X, 3*m*sizeof(double));

	int opt[4];
	opt[0] = 0; // default
	opt[1] = 0; // default
	opt[2] = 0; // default
	opt[3] = doRowCompression ? 1 : 0;
	int nnz;
	unsigned int *ridxs, *cidxs;
	double *nzvals;
	int samePattern = 0;
	for (int i = 0; i < nruns; i++)
	{
		sparse_jac(tapeTag, Jrows, Jcols, samePattern, in, &nnz, &ridxs, &cidxs, &nzvals, opt);
		samePattern = 1;
		
	}
	delete[] ridxs;
	delete[] cidxs;
	delete[] nzvals;

	end = high_resolution_clock::now();
	return duration_cast<duration<double>>(end - start).count() / nruns;
}

void test_ba(char *argv[])
{
	int n, m, p;
	double *cams, *X, *feats;
	int *obs;
	int nCamParams = 11;

	//read instance
	string fn(argv[1]);
	read_ba_instance(fn + ".txt", n, m, p, cams, X, obs, feats);

	int Jcols = nCamParams * n + 3 * m;
	int Jrows = p;

	double *err = new double[p];
	double **J = new double*[Jrows];
	for (int i = 0; i < Jrows; i++)
	{
		J[i] = new double[Jcols];
	}

	high_resolution_clock::time_point start, end;
	double tf, tJ;
	int nruns = 1;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		ba(n, m, p, cams, X, obs, feats, err);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;
	cout << "ba runtime: " << tf << "s" << endl;

	bool doRowCompression = false;
	tJ = compute_ba_J(doRowCompression, nruns, n, m, p, cams, X, obs, feats, err, J);
	cout << "ba_J runtime: " << tJ << "s" << endl;

	write_J(fn + "J_ADOLC.txt", Jrows, Jcols, J);
	write_times(fn + "_times_ADOLC.txt", tf, tJ);


	delete[] err;
	for (int i = 0; i < Jrows; i++)
	{
		delete[] J[i];
	}
	delete[] J;

	delete[] cams;
	delete[] X;
	delete[] obs;
	delete[] feats;
}

int main(int argc, char *argv[])
{
	test_gmm(argv);
	//test_ba(argv);
}