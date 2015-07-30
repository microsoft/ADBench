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
#include "ba_dv.h"
#include "ba_bv.h"
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
/*
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
*/

void compute_reproj_error_Jdv_block(int n, int m, int obsIdx,
	int camIdx, int ptIdx, double *cam, double *X,double w, 
	double *feat, double *reproj_err,SparseMat& J)
{
	double camd[BA_NCAMPARAMS][NB_DIRS_REPROJ_DV];
	double Xd[3][NB_DIRS_REPROJ_DV];
	double wd[NB_DIRS_REPROJ_DV];
	for (int i = 0; i < BA_NCAMPARAMS; i++)
	{
		memset(camd[i], 0, NB_DIRS_REPROJ_DV*sizeof(double));
		camd[i][i] = 1.;
	}
	int offset = BA_NCAMPARAMS;
	for (int i = 0; i < 3; i++)
	{
		memset(Xd[i], 0, NB_DIRS_REPROJ_DV * sizeof(double));
		Xd[i][offset + i] = 1.;
	}
	offset += 3;
	memset(wd, 0, NB_DIRS_REPROJ_DV*sizeof(double));
	wd[offset] = 1.;

	double errd[2][NB_DIRS_REPROJ_DV];
	for (int i = 0; i < 2; i++)
		memset(errd[i], 0, NB_DIRS_REPROJ_DV*sizeof(double));

	computeReprojError_dv(cam, camd, X, Xd, &w, &wd,
		feat[0], feat[1], reproj_err, errd, NB_DIRS_REPROJ_DV);

	J.rows.push_back(J.rows.back() + NB_DIRS_REPROJ_DV);
	J.rows.push_back(J.rows.back() + NB_DIRS_REPROJ_DV);

	for (int i_row = 0; i_row < 2; i_row++)
	{
		for (int i = 0; i < BA_NCAMPARAMS; i++)
		{
			J.cols.push_back(BA_NCAMPARAMS*camIdx + i);
			J.vals.push_back(errd[i_row][i]);
		}
		int col_offset = BA_NCAMPARAMS*n;
		int val_offset = BA_NCAMPARAMS;
		for (int i = 0; i < 3; i++)
		{
			J.cols.push_back(col_offset + 3 * ptIdx + i);
			J.vals.push_back(errd[i_row][val_offset + i]);
		}
		col_offset += 3 * m;
		val_offset += 3;
		J.cols.push_back(col_offset + obsIdx);
		J.vals.push_back(errd[i_row][val_offset]);
	}
}

void compute_f_prior_error_Jdv_block(int cam1_idx,
	double *cam1,double *cam2, double *cam3, 
	double *f_prior_err, SparseMat& J)
{

	double camsd[3][BA_NCAMPARAMS][NB_DIRS_F_PRIOR_DV];
	for (int i = 0; i < 3; i++)
	{
		int offset = i * BA_NCAMPARAMS;
		for (int j = 0; j < BA_NCAMPARAMS; j++)
		{
			memset(camsd[i][j], 0, NB_DIRS_F_PRIOR_DV*sizeof(double));
			camsd[i][j][offset + j] = 1.;
		}
	}

	double errd[NB_DIRS_F_PRIOR_DV];
	memset(errd, 0, NB_DIRS_F_PRIOR_DV*sizeof(double));

	computeFocalPriorError_dv(cam1, camsd[0], cam2, camsd[1],
		cam3, camsd[2], f_prior_err, &errd, NB_DIRS_F_PRIOR_DV);

	J.rows.push_back(J.rows.back() + NB_DIRS_F_PRIOR_DV);

	int nbdir_idx = 0;
	for (int i = 0; i < 3; i++)
	{
		int col_offset = (cam1_idx+i)* BA_NCAMPARAMS;
		for (int j = 0; j < BA_NCAMPARAMS; j++)
		{
			J.cols.push_back(col_offset + j);
			J.vals.push_back(errd[nbdir_idx]);
			nbdir_idx++;
		}
	}
}

void compute_w_error_Jdv_block(int n,
	int m, int wIdx, double w,
	double *w_err, SparseMat& J)
{
	double wd = 1.;
	double errd = 0.;

	computeZachWeightError_dv(&w, &wd, w_err, &errd);

	J.rows.push_back(J.rows.back() + 1);
	J.cols.push_back(BA_NCAMPARAMS*n + 3 * m + wIdx);
	J.vals.push_back(errd);
}

void compute_ba_Jdv(int n, int m, int p, double *cams, double *X,
	double *w, int *obs, double *feats, double *reproj_err,
	double *f_prior_err, double *w_err, SparseMat& J)
{
	J.nrows = 2 * p + n - 2 + p;
	J.ncols = BA_NCAMPARAMS*n + 3 * m + p;
	J.rows.push_back(0);

	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[2 * i + 0];
		int ptIdx = obs[2 * i + 1];
		compute_reproj_error_Jdv_block(n, m, i, camIdx, ptIdx,
			&cams[BA_NCAMPARAMS*camIdx],&X[ptIdx*3],
			w[i],&feats[2*i],&reproj_err[2*i],J);
	}

	for (int i = 0; i < n-2; i++)
	{
		int idx1 = BA_NCAMPARAMS * i;
		int idx2 = BA_NCAMPARAMS * (i+1);
		int idx3 = BA_NCAMPARAMS * (i+2);
		compute_f_prior_error_Jdv_block(i,
			&cams[idx1], &cams[idx2], &cams[idx3],
			&f_prior_err[i], J);
	}

	for (int i = 0; i < p; i++)
	{
		compute_w_error_Jdv_block(n, m, i, w[i], &w_err[i], J);
	}
}

void compute_reproj_error_Jbv_block(int n, int m, int obsIdx,
	int camIdx, int ptIdx, double *cam, double *X, double w,
	double *feat, double *reproj_err, SparseMat& J)
{
	double camb[BA_NCAMPARAMS][NB_DIRS_REPROJ_BV];
	double Xb[3][NB_DIRS_REPROJ_BV];
	double wb[NB_DIRS_REPROJ_BV];
	for (int i = 0; i < BA_NCAMPARAMS; i++)
		memset(camb[i], 0, NB_DIRS_REPROJ_BV*sizeof(double));
	for (int i = 0; i < 3; i++)
		memset(Xb[i], 0, NB_DIRS_REPROJ_BV * sizeof(double));
	memset(wb, 0, NB_DIRS_REPROJ_BV*sizeof(double));

	double errb[2][NB_DIRS_REPROJ_BV];
	errb[0][0] = 1.;
	errb[0][1] = 0.;
	errb[1][0] = 0.;
	errb[1][1] = 1.;

	computeReprojError_bv(cam, camb, X, Xb, &w, &wb,
		feat[0], feat[1], reproj_err, errb, NB_DIRS_REPROJ_BV);

	int n_new_cols = NB_DIRS_REPROJ_DV;
	J.rows.push_back(J.rows.back() + n_new_cols);
	J.rows.push_back(J.rows.back() + n_new_cols);

	for (int i_row = 0; i_row < 2; i_row++)
	{
		for (int i = 0; i < BA_NCAMPARAMS; i++)
		{
			J.cols.push_back(BA_NCAMPARAMS*camIdx + i);
			J.vals.push_back(camb[i][i_row]);
		}
		int col_offset = BA_NCAMPARAMS*n;
		int val_offset = BA_NCAMPARAMS;
		for (int i = 0; i < 3; i++)
		{
			J.cols.push_back(col_offset + 3 * ptIdx + i);
			J.vals.push_back(Xb[i][i_row]);
		}
		col_offset += 3 * m;
		val_offset += 3;
		J.cols.push_back(col_offset + obsIdx);
		J.vals.push_back(wb[i_row]);
	}
}

void compute_f_prior_error_Jb_block(int cam1_idx,
	double *cam1, double *cam2, double *cam3,
	double *f_prior_err, SparseMat& J)
{
	double camsb[3][BA_NCAMPARAMS];
	for (int i = 0; i < 3; i++)
		memset(camsb[i], 0, BA_NCAMPARAMS*sizeof(double));
	
	double errb = 1.;

	computeFocalPriorError_b(cam1, camsb[0], cam2, camsb[1],
		cam3, camsb[2], f_prior_err, &errb);

	int n_new_cols = NB_DIRS_F_PRIOR_DV;
	J.rows.push_back(J.rows.back() + n_new_cols);

	for (int i = 0; i < 3; i++)
	{
		int col_offset = (cam1_idx + i)* BA_NCAMPARAMS;
		for (int j = 0; j < BA_NCAMPARAMS; j++)
		{
			J.cols.push_back(col_offset + j);
			J.vals.push_back(camsb[i][j]);
		}
	}
}

void compute_w_error_Jb_block(int n,
	int m, int wIdx, double w,
	double *w_err, SparseMat& J)
{
	double wb = 0.;
	double errb = 1.;

	computeZachWeightError_b(&w, &wb, w_err, &errb);

	J.rows.push_back(J.rows.back() + 1);
	J.cols.push_back(BA_NCAMPARAMS*n + 3 * m + wIdx);
	J.vals.push_back(wb);
}

void compute_ba_Jbv(int n, int m, int p, double *cams, double *X,
	double *w, int *obs, double *feats, double *reproj_err,
	double *f_prior_err, double *w_err, SparseMat& J)
{
	J.nrows = 2 * p + n - 2 + p;
	J.ncols = BA_NCAMPARAMS*n + 3 * m + p;
	J.rows.push_back(0);

	for (int i = 0; i < p; i++)
	{
		int camIdx = obs[2 * i + 0];
		int ptIdx = obs[2 * i + 1];
		compute_reproj_error_Jbv_block(n, m, i, camIdx, ptIdx,
			&cams[BA_NCAMPARAMS*camIdx], &X[ptIdx * 3],
			w[i], &feats[2 * i], &reproj_err[2 * i], J);
	}

	for (int i = 0; i < n - 2; i++)
	{
		int idx1 = BA_NCAMPARAMS * i;
		int idx2 = BA_NCAMPARAMS * (i + 1);
		int idx3 = BA_NCAMPARAMS * (i + 2);
		compute_f_prior_error_Jb_block(i,
			&cams[idx1], &cams[idx2], &cams[idx3],
			&f_prior_err[i], J);
	}

	for (int i = 0; i < p; i++)
	{
		compute_w_error_Jb_block(n, m, i, w[i], &w_err[i], J);
	}
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

	double *reproj_err = new double[2*p];
	double *f_prior_err = new double[n-2];
	double *w_err = new double[p];
	SparseMat J;

	high_resolution_clock::time_point start, end;
	double tf, tJ;
	int nruns = 1000;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		ba_objective(n, m, p, cams, X, w, 
			obs, feats, reproj_err, f_prior_err, w_err);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;

	/*start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		J = SparseMat();
		compute_ba_Jdv(n, m, p, cams, X, w, obs, feats,
			reproj_err, f_prior_err, w_err, J);
	}
	end = high_resolution_clock::now();
	tJ = duration_cast<duration<double>>(end - start).count() / nruns;*/

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		J = SparseMat();
		compute_ba_Jbv(n, m, p, cams, X, w, obs, feats,
			reproj_err, f_prior_err, w_err, J);
	}
	end = high_resolution_clock::now();
	tJ = duration_cast<duration<double>>(end - start).count() / nruns;

	//write_J_sparse(fn + "J_Tapenade_dv.txt", J);
	write_J_sparse(fn + "J_Tapenade_bv.txt", J);
	write_times(tf, tJ);

	delete[] reproj_err;
	delete[] f_prior_err;
	delete[] w_err;

	delete[] cams;
	delete[] X;
	delete[] obs;
	delete[] feats;
}

int main(int argc, char *argv[])
{
	//test_gmm(argv);
	test_ba(argv);
}