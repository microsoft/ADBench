#include <iostream>
#include <string>
#include <chrono>
#include <set>

#include "adolc/adolc.h"
#include "adolc/adolc_sparse.h"
#include "../utils.h"
#include "../defs.h"

//#define DO_GMM_FULL
//#define DO_GMM_SPLIT
#define DO_BA_BLOCK
//#define DO_BA_SPARSE

#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
#include "gmm.h"
#elif defined DO_BA_BLOCK || defined DO_BA_SPARSE
#include "ba.h"
#endif

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

#ifdef DO_GMM_FULL

double compute_gmm_J(int nruns,
	int d, int k, int n, double *alphas, 
	double *means, double *icf, double *x, 
	Wishart wishart, double& err, double *J)
{
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


	high_resolution_clock::time_point start, end;
	start = high_resolution_clock::now();

	// Compute J
	double *in = new double[Jcols];
	memcpy(in, alphas, k*sizeof(double));
	int off = k;
	memcpy(in + off, means, d*k*sizeof(double));
	off += d*k;
	memcpy(in + off, icf, icf_sz*k*sizeof(double));

	for (int i = 0; i < nruns; i++)
	{
		gradient(tapeTag, Jcols, in, J);

		//int keepValues = 1;
		//double errd = 1;
		//zos_forward(tapeTag, Jrows, Jcols, keepValues, in, &err);
		//fos_reverse(tapeTag, Jrows, Jcols, &errd, J[0]);
	}

	end = high_resolution_clock::now();

	delete[] in;

  return duration_cast<duration<double>>(end - start).count() / nruns;
}

#elif defined DO_GMM_SPLIT

double compute_gmm_J_split(int nruns,
  int d, int k, int n, double *alphas,
  double *means, double *icf, double *x,
  Wishart wishart, double& err, double *J)
{
  int innerTapeTag = 1;
  int otherTapeTag = 0;
  int icf_sz = d*(d + 1) / 2;
  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;
  adouble *aalphas, *ameans, *aicf, aerr;
  aalphas = new adouble[k];
  ameans = new adouble[d*k];
  aicf = new adouble[icf_sz*k];

  // Record on a tape
  trace_on(otherTapeTag);

  for (int i = 0; i < k; i++)
    aalphas[i] <<= alphas[i];
  for (int i = 0; i < d*k; i++)
    ameans[i] <<= means[i];
  for (int i = 0; i < icf_sz*k; i++)
    aicf[i] <<= icf[i];

  gmm_objective_split_other(d, k, n, aalphas, ameans,
    aicf, wishart, &aerr);

  aerr >>= err;

  trace_off();

  high_resolution_clock::time_point start, end;
  start = high_resolution_clock::now();

  // Compute J
  double *in = new double[Jcols];
  memcpy(in, alphas, k*sizeof(double));
  int off = k;
  memcpy(in + off, means, d*k*sizeof(double));
  off += d*k;
  memcpy(in + off, icf, icf_sz*k*sizeof(double));

  double *Jtmp = new double[Jcols];
  for (int i = 0; i < nruns; i++)
  {
    gradient(otherTapeTag, Jcols, in, J);
    for (int i = 0; i < n; i++)
    {
      // Record on a tape
      int keepValues = 1; // those are used for gradient right after
      trace_on(innerTapeTag, keepValues);

      for (int i = 0; i < k; i++)
        aalphas[i] <<= alphas[i];
      for (int i = 0; i < d*k; i++)
        ameans[i] <<= means[i];
      for (int i = 0; i < icf_sz*k; i++)
        aicf[i] <<= icf[i];

      gmm_objective_split_inner(d, k, aalphas, ameans,
        aicf, &x[i*d], wishart, &aerr);

      aerr >>= err;

      trace_off();

      gradient(innerTapeTag, Jcols, in, Jtmp);
      for (int i = 0; i < Jcols; i++)
      {
        J[i] += Jtmp[i];
      }
    }

    //int keepValues = 1;
    //double errd = 1;
    //zos_forward(tapeTag, Jrows, Jcols, keepValues, in, &err);
    //fos_reverse(tapeTag, Jrows, Jcols, &errd, J[0]);
  }

  end = high_resolution_clock::now();

  delete[] aalphas;
  delete[] ameans;
  delete[] aicf;
  delete[] Jtmp;
  delete[] in;

  return duration_cast<duration<double>>(end - start).count() / nruns;
}

#endif
#if defined DO_GMM_FULL || defined DO_GMM_SPLIT

void test_gmm(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, bool replicate_point)
{
  int d, k, n;
  vector<double> alphas, means, icf, x;
  double err;
  Wishart wishart;

  // Read instance
  read_gmm_instance(fn_in + ".txt", &d, &k, &n,
    alphas, means, icf, x, wishart, replicate_point);

  int icf_sz = d*(d + 1) / 2;
  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  vector<double> J(Jcols);

  // Test
  high_resolution_clock::time_point start, end;
  double tf, tJ = 0.;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    gmm_objective(d, k, n, alphas.data(), means.data(),
      icf.data(), x.data(), wishart, &err);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;
  cout << "err: " << err << endl;

#ifdef DO_GMM_FULL
  string name = "ADOLC";
  tJ = compute_gmm_J(nruns_J, d, k, n, alphas.data(), means.data(), icf.data(), 
    x.data(), wishart, err, J.data());
#elif defined DO_GMM_SPLIT
  string name = "ADOLC_split";
  tJ = compute_gmm_J_split(nruns_J, d, k, n, alphas.data(), means.data(), icf.data(),
    x.data(), wishart, err, J.data());
#endif
  cout << "err: " << err << endl;

  write_J(fn_out + "_J_" + name + ".txt", Jrows, Jcols, J.data());
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);

}

#elif defined DO_BA_BLOCK
double compute_ba_J(int nruns, int n, int m, int p,
  double *cams, double *X, double *w, int *obs, double *feats,
  double *reproj_err, double *w_err, BASparseMat *J)
{
  if (nruns == 0)
    return 0.;

  bool doRowCompression = false;
  high_resolution_clock::time_point start, end;

  int tapeTag = 1;

  start = high_resolution_clock::now();

  adouble *acams, *aX, *aw, *areproj_err,
    *af_prior_err, *aw_err;

  areproj_err = new adouble[2 * p];
  af_prior_err = new adouble[n - 2];
  aw_err = new adouble[p];

  // Record on a tape
  trace_on(tapeTag);

  acams = new adouble[BA_NCAMPARAMS*n];
  for (int i = 0; i < BA_NCAMPARAMS*n; i++)
    acams[i] <<= cams[i];
  aX = new adouble[3 * m];
  for (int i = 0; i < 3 * m; i++)
    aX[i] <<= X[i];
  aw = new adouble[p];
  for (int i = 0; i < p; i++)
    aw[i] <<= w[i];

  ba_objective(n, m, p, acams, aX, aw, obs, feats,
    areproj_err, aw_err);

  for (int i = 0; i < 2 * p; i++)
    areproj_err[i] >>= reproj_err[i];

  for (int i = 0; i < p; i++)
    aw_err[i] >>= w_err[i];

  trace_off();

  delete[] acams;
  delete[] aX;
  delete[] aw;
  delete[] areproj_err;
  delete[] af_prior_err;
  delete[] aw_err;

  end = high_resolution_clock::now();
  double t_tape = duration_cast<duration<double>>(end - start).count() / nruns;

  //////// Compute J and compute sparsity always again and again
  vector<double> in(J->ncols);
  memcpy(&in[0], cams, BA_NCAMPARAMS*n*sizeof(double));
  int off = BA_NCAMPARAMS*n;
  memcpy(&in[off], X, 3 * m*sizeof(double));
  off += 3 * m;
  memcpy(&in[off], w, p*sizeof(double));

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
  sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
    in.data(), &nnz, &ridxs, &cidxs, &nzvals, opt);
  end = high_resolution_clock::now();
  double t_J_sparsity = duration_cast<duration<double>>(end - start).count() / nruns;

  samePattern = 1;
  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
      in.data(), &nnz, &ridxs, &cidxs, &nzvals, opt);
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

#elif defined DO_BA_SPARSE
void convert_J(int nnz, unsigned int *ridxs, unsigned int *cidxs,
  double *nzvals, BASparseMat *J)
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

double compute_ba_J(int nruns, int n, int m, int p,
  double *cams, double *X, double *w, int *obs, double *feats,
  double *reproj_err, double *w_err, BASparseMat *J)
{
  if (nruns == 0)
    return 0.;

  bool doRowCompression = false;
  high_resolution_clock::time_point start, end;

  int tapeTag = 1;

  start = high_resolution_clock::now();

  adouble *acams, *aX, *aw, *areproj_err,
    *af_prior_err, *aw_err;

  areproj_err = new adouble[2 * p];
  af_prior_err = new adouble[n - 2];
  aw_err = new adouble[p];

  // Record on a tape
  trace_on(tapeTag);

  acams = new adouble[BA_NCAMPARAMS*n];
  for (int i = 0; i < BA_NCAMPARAMS*n; i++)
    acams[i] <<= cams[i];
  aX = new adouble[3 * m];
  for (int i = 0; i < 3 * m; i++)
    aX[i] <<= X[i];
  aw = new adouble[p];
  for (int i = 0; i < p; i++)
    aw[i] <<= w[i];

  ba_objective(n, m, p, acams, aX, aw, obs, feats,
    areproj_err, aw_err);

  for (int i = 0; i < 2 * p; i++)
    areproj_err[i] >>= reproj_err[i];

  for (int i = 0; i < p; i++)
    aw_err[i] >>= w_err[i];

  trace_off();

  delete[] acams;
  delete[] aX;
  delete[] aw;
  delete[] areproj_err;
  delete[] af_prior_err;
  delete[] aw_err;

  end = high_resolution_clock::now();
  double t_tape = duration_cast<duration<double>>(end - start).count() / nruns;

  //////// Compute J and compute sparsity always again and again
  vector<double> in(J->ncols);
  memcpy(&in[0], cams, BA_NCAMPARAMS*n*sizeof(double));
  int off = BA_NCAMPARAMS*n;
  memcpy(&in[off], X, 3 * m*sizeof(double));
  off += 3 * m;
  memcpy(&in[off], w, p*sizeof(double));

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
  sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
    in.data(), &nnz, &ridxs, &cidxs, &nzvals, opt);
  end = high_resolution_clock::now();
  double t_J_sparsity = duration_cast<duration<double>>(end - start).count() / nruns;

  samePattern = 1;
  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    sparse_jac(tapeTag, J->nrows, J->ncols, samePattern,
      in.data(), &nnz, &ridxs, &cidxs, &nzvals, opt);
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
#endif

#if defined DO_BA_BLOCK || defined DO_BA_SPARSE
void test_ba(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J)
{
  int n, m, p;
  vector<double> cams, X, w, feats;
  vector<int> obs;

  read_ba_instance(fn_in + ".txt", n, m, p,
    cams, X, w, obs, feats);

  vector<double> reproj_err(2 * p);
  vector<double> w_err(p);
  BASparseMat J(n, m, p);

  high_resolution_clock::time_point start, end;
  double tf = 0., tJ = 0;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    ba_objective(n, m, p, cams.data(), X.data(), 
      w.data(), obs.data(), feats.data(),
      reproj_err.data(), w_err.data());
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;

#if defined DO_BA_BLOCK
  string name("ADOLC");
  tJ = compute_ba_J(nruns_J, n, m, p, cams, X, w,
    obs, feats, reproj_err, w_err, &J);
#elif defined DO_BA_SPARSE
  string name("ADOLC_sparse");
  tJ = compute_ba_J(nruns_J, n, m, p, cams.data(), X.data(), w.data(),
    obs.data(), feats.data(), reproj_err.data(), w_err.data(), &J);
#endif

  write_J_sparse(fn_in + "_J_" + name + ".txt", J);
  write_times(fn_in + "_times_" + name + ".txt", tf, tJ);
}
#endif

#if 0


#endif

int main(int argc, char *argv[])
{
  string dir_in(argv[1]);
  string dir_out(argv[2]);
  string fn(argv[3]);
  int nruns_f = std::stoi(string(argv[4]));
  int nruns_J = std::stoi(string(argv[5]));

  // read only 1 point and replicate it?
  bool replicate_point = (argc >= 7 && string(argv[6]).compare("-rep") == 0);
  
#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
  test_gmm(dir_in + fn, dir_out + fn, nruns_f, nruns_J, replicate_point);
#elif defined DO_BA_BLOCK || defined DO_BA_SPARSE
  test_ba(dir_in + fn, dir_out + fn, nruns_f, nruns_J);
#endif
}