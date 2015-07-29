#include <cstring>
#include <chrono>
#include <iostream>
#include <random>
#include <string>
#include <fstream>

#include "../defs.h"
#include "../utils.h"

extern "C"
{
#include "gmm.h"
#include "gmm_b.h"
#include "gmm_dv.h"
#include "ba.h"
}

using std::cin;
using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

void compute_gmm_Jb(int d, int k, int n,
	double* alphas, double* means, 
	double* icf, double* x, Wishart wishart,
	double& err, double* Jb)
{
	int icf_sz = d*(d + 1) / 2;
	double *alphasb = new double[k];
	double *meansb = new double[d*k];
	double *icfb = new double[icf_sz*k];

	double eb = 1.;
	memset(alphasb, 0, k*sizeof(double));
	memset(meansb, 0, d*k*sizeof(double));
	memset(icfb, 0, icf_sz*k*sizeof(double));

	gmm_objective_b(d, k, n, alphas, alphasb, means, meansb,
		icf, icfb, x, wishart, &err, &eb);

	memcpy(Jb, alphasb, k*sizeof(double));
	memcpy(Jb + k, meansb, d*k*sizeof(double));
	memcpy(Jb + k + d*k, icfb, icf_sz*k*sizeof(double));

	delete[] alphasb;
	delete[] meansb;
	delete[] icfb;
}

void compute_gmm_Jdv(int d, int k, int n,
	double* alphas, double* means, 
	double* icf, double* x, Wishart wishart,
	double& err, double* Jdv)
{
	int icf_sz = d*(d + 1) / 2;
	int nbdirs = k + d*k + icf_sz*k;
	double(*alphasdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(k*sizeof(double)*NBDirsMax);
	double(*meansdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(d*k*sizeof(double)*NBDirsMax);
	double(*icfdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(icf_sz*k*sizeof(double)*NBDirsMax);

	for (int ik = 0; ik < k; ik++)
	{
		memset(alphasdv[ik], 0, nbdirs*sizeof(double));
		alphasdv[ik][ik] = 1.;
	}
	int nbdirs_off = k;
	for (int i = 0; i < d*k; i++)
	{
		memset(meansdv[i], 0, nbdirs*sizeof(double));
		meansdv[i][nbdirs_off + i] = 1.;
	}
	nbdirs_off += d*k;
	for (int i = 0; i < icf_sz*k; i++)
	{
		memset(icfdv[i], 0, nbdirs*sizeof(double));
		icfdv[i][nbdirs_off + i] = 1.;
	}

	double errdv[NBDirsMax];
	gmm_objective_dv(d, k, n, alphas, alphasdv, means, 
		meansdv, icf, icfdv,
		x, wishart, &err, &errdv, nbdirs);

	memcpy(Jdv, errdv, nbdirs * sizeof(double));

	free(alphasdv);
	free(meansdv);
	free(icfdv);
}

void test_gmm(char *argv[])
{
	int d, k, n;
	double *alphas, *means, *icf, *x;
	Wishart wishart;

	//read instance
	//string fn = "Z:\\gmm1";
	string fn(argv[1]);
	read_gmm_instance(fn + ".txt", d, k, n,
		alphas, means, icf, x, wishart);

	int icf_sz = d*(d + 1) / 2;
	int Jsz = (k*(d + 1)*(d + 2)) / 2;

	double e1, e3, e4;
	double *Jb = new double[Jsz];
	double *Jdv = new double[Jsz];

	high_resolution_clock::time_point start, end;
	double tf, tb = 0., tdv = 0.;
	int nruns = 1000;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		gmm_objective(d, k, n, alphas, means, 
			icf, x, wishart, &e1);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;


	/*start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		compute_gmm_Jb(d, k, n, alphas, 
			means, icf, x, wishart, e3, Jb);
	}
	end = high_resolution_clock::now();
	tb = duration_cast<duration<double>>(end - start).count() / nruns;*/


	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		compute_gmm_Jdv(d, k, n, alphas, 
			means, icf, x, wishart, e4, Jdv);
	}
	end = high_resolution_clock::now();
	tdv = duration_cast<duration<double>>(end - start).count() / nruns;

	/////////////////// results //////////////////////////
	//cout << "true_obj - b_obj = " << e1 - e3 << endl;
	//cout << "true_obj - dv_obj = " << e1 - e4 << endl;

	//write_J(fn + "J_Tapenade_b.txt", 1, Jsz, Jb);
	write_J(fn + "J_Tapenade_dv.txt", 1, Jsz, Jdv);
	//write_times(tf, tb);
	write_times(tf, tdv);

	delete[] Jb;
	delete[] Jdv;

	delete[] alphas;
	delete[] means;
	delete[] icf;
	delete[] x;
}

// Jb in column major
void compute_ba_Jb(int n, int m, int p, double *cams, double *X,
	int *obs, double *feats, double *Jb)
{
	int nCamParams = 11;
	double *camsb = new double[nCamParams*n];
	double *Xb = new double[3 * m];
	double *err = new double[p];
	double *errb = new double[p];

	for (int i = 0; i < p; i++)
	{
		memset(camsb, 0, nCamParams*n*sizeof(double));
		memset(Xb, 0, 3 * m*sizeof(double));
		memset(errb, 0, p*sizeof(double));
		errb[i] = 1.;
		ba_b(n, m, p, cams, camsb, X, Xb, obs, feats, err, errb);
		for (int j = 0; j < nCamParams*n; j++)
		{
			Jb[j*p + i] = camsb[j];
		}
		int Jb_off = nCamParams*n*p;
		for (int j = 0; j < 3*m; j++)
		{
			Jb[Jb_off + j*p + i] = Xb[j];
		}
	}

	delete[] camsb;
	delete[] Xb;
	delete[] err;
	delete[] errb;
}

// Jdv in column major
void compute_ba_Jdv(int n, int m, int p, double *cams, double *X,
	int *obs, double *feats, double *Jdv)
{
	int nCamParams = 11;
	int nbdirs = nCamParams*n + 3 * m;
	double(*camsdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(nCamParams*n*sizeof(double)*NBDirsMax);
	double(*Xdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(3*m*sizeof(double)*NBDirsMax);
	double *err = new double[p];
	double(*errdv)[NBDirsMax] = (double(*)[NBDirsMax])malloc(p*sizeof(double)*NBDirsMax);

	for (int i = 0; i < nCamParams*n; i++)
	{
		memset(&(camsdv[i]), 0, nbdirs*sizeof(double));
		camsdv[i][i] = 1.;
	}

	int nbdirs_off = nCamParams*n;
	for (int i = 0; i < 3 * m; i++)
	{
		memset(&(Xdv[i]), 0, nbdirs*sizeof(double));
		Xdv[i][nbdirs_off + i] = 1.;
	}

	ba_dv(n, m, p, cams, camsdv, X, Xdv, obs, feats, err, errdv,nbdirs);

	for (int i = 0; i < p; i++)
	{
		for (int j = 0; j < nbdirs; j++)
		{
			Jdv[j*p + i] = errdv[i][j];
		}
	}

	free(camsdv);
	free(Xdv);
	free(errdv);
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

	double *e1 = new double[p];
	double *Jd = new double[Jcols*Jrows];
	double *Jb = new double[Jcols*Jrows];
	double *Jdv = new double[Jcols*Jrows];
	double *Jbv = new double[Jcols*Jrows];

	high_resolution_clock::time_point start, end;
	double tf, td = 0, tb = 0., tdv = 0., tbv = 0.;
	int nruns = 100;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		ba(n, m, p, cams, X, obs, feats, e1);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;
	cout << "ba runtime: " << tf << "s" << endl;

	/*start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		compute_ba_Jd(n, m, p, cams, X, obs, feats, Jd);
	}
	end = high_resolution_clock::now();
	td = duration_cast<duration<double>>(end - start).count() / nruns;
	cout << "ba_d runtime: " << td << "s" << endl;*/

	/*start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		compute_ba_Jb(n, m, p, cams, X, obs, feats, Jb);
	}
	end = high_resolution_clock::now();
	tb = duration_cast<duration<double>>(end - start).count() / nruns;
	cout << "ba_b runtime: " << tb << "s" << endl;*/

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		compute_ba_Jdv(n, m, p, cams, X, obs, feats, Jdv);
	}
	end = high_resolution_clock::now();
	tdv = duration_cast<duration<double>>(end - start).count() / nruns;
	cout << "ba_dv runtime: " << tdv << "s" << endl;

	/////////////////// compare results //////////////////////////
	//double max_J_diff1 = compare_J(Jcols*Jrows, Jd, Jb);
	//double max_J_diff2 = compare_J(Jcols*Jrows, Jd, Jdv);
	//cout << "max(abs(Jd-Jb)) = " << max_J_diff1 << endl;
	//cout << "max(abs(Jd-Jdv)) = " << max_J_diff2 << endl;

	//write_J(fn + "Jdv.txt", Jrows, Jcols, Jdv);
	//write_times(fn + "_times.txt", tf, td, tb, tdv);

	delete[] e1;
	delete[] Jd;
	delete[] Jb;
	delete[] Jdv;

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