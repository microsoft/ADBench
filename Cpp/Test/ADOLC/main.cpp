#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <vector>
#include <set>

#include "adolc/adolc.h"
#include "adolc/adolc_sparse.h"
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
	int nruns = 1;

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
	delete[] x;
	delete[] icf;
}

void convert_J(int nnz, unsigned int *ridxs, unsigned int *cidxs,
	double *nzvals, SparseMat *J)
{
	std::vector<std::set<int>> rows;
	rows.resize(J->nrows);
	for (int i = 0; i < nnz; i++)
	{
		rows[ridxs[i]].insert(i);
	}

	J->rows.resize(J->nrows + 1, 0);
	J->cols.resize(nnz);
	J->vals.resize(nnz);
	int cols_idx = 0;
	for (int i = 0; i < J->nrows; i++)
	{
		for (auto j : rows[i])
		{
			J->cols[cols_idx] = cidxs[j];
			J->vals[cols_idx] = nzvals[j];
			cols_idx++;
		}
		J->rows[i + 1] = cols_idx;
	}
}

double compute_ba_J(bool doRowCompression,int nruns, int n, int m, int p, 
	double *cams, double *X, double *w, int *obs, double *feats, 
	double *reproj_err, double *f_prior_err, double *w_err, SparseMat *J)
{
	high_resolution_clock::time_point start, end;

	int tapeTag = 1;

	start = high_resolution_clock::now();
	for (int i = 0; i < 1; i++)
	{
		adouble *acams, *aX, *aw, *areproj_err,
			*af_prior_err, *aw_err;

		areproj_err = new adouble[2 * p];
		af_prior_err = new adouble[n - 2];
		aw_err = new adouble[p];

		// Record on a tape
		trace_on(tapeTag);

		acams = new adouble[BA_NCAMPARAMS*n];
		for (int i = 0; i < BA_NCAMPARAMS*n; i++)
		{
			acams[i] <<= cams[i];
		}

		aX = new adouble[3 * m];
		for (int i = 0; i < 3 * m; i++)
		{
			aX[i] <<= X[i];
		}

		aw = new adouble[p];
		for (int i = 0; i < p; i++)
		{
			aw[i] <<= w[i];
		}

		ba_objective(n, m, p, acams, aX, aw, obs, feats, areproj_err,
			af_prior_err, aw_err);

		for (int i = 0; i < 2 * p; i++)
		{
			areproj_err[i] >>= reproj_err[i];
		}

		for (int i = 0; i < n - 2; i++)
		{
			af_prior_err[i] >>= f_prior_err[i];
		}

		for (int i = 0; i < p; i++)
		{
			aw_err[i] >>= w_err[i];
		}

		trace_off();

		delete[] acams;
		delete[] aX;
		delete[] aw;
		delete[] areproj_err;
		delete[] af_prior_err;
		delete[] aw_err;
	}
	end = high_resolution_clock::now();
	double t_tape = duration_cast<duration<double>>(end - start).count() / nruns;

	//////// Compute J and compute sparsity always again and again
	double *in = new double[J->ncols];
	memcpy(in, cams, BA_NCAMPARAMS*n*sizeof(double));
	int off = BA_NCAMPARAMS*n;
	memcpy(in + off, X, 3 * m*sizeof(double));
	off += 3*m;
	memcpy(in + off, w, p*sizeof(double));

	int opt[4];
	opt[0] = 0; // default
	opt[1] = 0; // default
	opt[2] = 0; // 0=auto 1=F 2=R
	opt[3] = doRowCompression ? 1 : 0;
	int nnz;
	unsigned int *ridxs = nullptr, *cidxs = nullptr;
	double *nzvals = nullptr;

	int samePattern = 0;
	start = high_resolution_clock::now();
	for (int i = 0; i < 1; i++)
	{
		delete[] ridxs; ridxs = nullptr;
		delete[] cidxs; cidxs = nullptr;
		delete[] nzvals; nzvals = nullptr;
		sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
			in, &nnz, &ridxs, &cidxs, &nzvals, opt);
	}
	end = high_resolution_clock::now();
	double t_J_sparsity = duration_cast<duration<double>>(end - start).count() / nruns;

	samePattern = 1;
	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
			in, &nnz, &ridxs, &cidxs, &nzvals, opt);
	}
	end = high_resolution_clock::now();
	double t_J = duration_cast<duration<double>>(end - start).count() / nruns;

	convert_J(nnz, ridxs, cidxs, nzvals, J);

	delete[] ridxs;
	delete[] cidxs;
	delete[] nzvals;

	cout << "t_tape: " << t_tape << endl;
	cout << "t_sparsity: " << t_J_sparsity - t_J << endl;
	cout << "t_J:" << t_J << endl;

	return t_J;
}

void test_ba(char *argv[])
{
	int n, m, p;
	double *cams, *X, *w, *feats;
	int *obs;

	//read instance
	string fn(argv[1]);
	read_ba_instance(fn + ".txt", n, m, p, 
		cams, X, w, obs, feats);

	SparseMat J;
	J.ncols = BA_NCAMPARAMS * n + 3 * m + p;
	J.nrows = 2 * p + n - 2 + p;

	double *reproj_err = new double[2 * p];
	double *f_prior_err = new double[n-2];
	double *w_err = new double[p];

	high_resolution_clock::time_point start, end;
	double tf, tJ = 0;
	int nruns = 10000;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		ba_objective(n, m, p, cams, X, w, obs, feats, 
			reproj_err, f_prior_err, w_err);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;

	/*bool doRowCompression = false;
	tJ = compute_ba_J(doRowCompression, nruns, n, m, p, cams, X, w, 
		obs, feats, reproj_err, f_prior_err, w_err, &J);

	write_J_sparse(fn + "J_ADOLC.txt", J);*/
	write_times(tf, tJ);

	delete[] reproj_err;
	delete[] f_prior_err;
	delete[] w_err;

	delete[] cams;
	delete[] X;
	delete[] w;
	delete[] obs;
	delete[] feats;
}

int main(int argc, char *argv[])
{
	test_gmm(argv);
	//test_ba(argv);
}