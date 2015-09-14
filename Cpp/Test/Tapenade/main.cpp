#include <cstring>
#include <chrono>
#include <iostream>
#include <random>
#include <string>
#include <vector>
#include <fstream>

#include "../defs.h"
#include "../utils.h"

//#define DO_GMM_FULL
//#define DO_GMM_SPLIT
#define DO_BA

extern "C"
{
#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
#include "gmm.h"
#include "gmm_b.h"
#elif defined DO_BA
#include "ba.h"
#include "ba_bv.h"
#endif
}

using std::cin;
using std::cout;
using std::endl;
using std::string;
using std::vector;
using namespace std::chrono;

#if defined DO_GMM_FULL
void compute_gmm_Jb(int d, int k, int n,
  double* alphas, double* means,
  double* icf, double* x, Wishart wishart,
  double& err, double* Jb)
{
  int Jsz = (k*(d + 1)*(d + 2)) / 2;

  double eb = 1.;
  memset(Jb, 0, Jsz*sizeof(double));

  double *alphasb = &Jb[0];
  double *meansb = &Jb[k];
  double *icfb = &Jb[k + d*k];

  gmm_objective_b(d, k, n, alphas, alphasb, means, meansb,
    icf, icfb, x, wishart, &err, &eb);
}

#elif defined DO_GMM_SPLIT
void compute_gmm_Jb(int d, int k, int n,
  double* alphas, double* means,
  double* icf, double* x, Wishart wishart,
  double& err, double* Jb)
{
  int Jsz = (k*(d + 1)*(d + 2)) / 2;

  double eb = 1.;
  memset(Jb, 0, Jsz*sizeof(double));

  double *alphasb = &Jb[0];
  double *meansb = &Jb[k];
  double *icfb = &Jb[k + d*k];

  gmm_objective_split_other_b(d, k, n, alphas, alphasb,
    icf, icfb, wishart, &err, &eb);

  vector<double> Jtmp(Jsz);
  double *alphasb_tmp = &Jtmp[0];
  double *meansb_tmp = &Jtmp[k];
  double *icfb_tmp = &Jtmp[k + d*k];
  for (int i = 0; i < n; i++)
  {
    double err_tmp;
    eb = 1.;
    memset(Jtmp.data(), 0, Jsz*sizeof(double));
    gmm_objective_split_inner_b(d, k, alphas, alphasb_tmp, means, meansb_tmp,
      icf, icfb_tmp, &x[i*d], &err_tmp, &eb);

    err += err_tmp;
    for (int j = 0; j < Jsz; j++)
    {
      Jb[j] += Jtmp[j];
    }
  }
}
#endif

#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
void test_gmm(const string& fn_in, const string& fn_out, 
  int nruns_f, int nruns_J, bool replicate_point)
{
  int d, k, n;
  vector<double> alphas, means, icf, x;
  Wishart wishart;

  //read instance
  read_gmm_instance(fn_in + ".txt", &d, &k, &n,
    alphas, means, icf, x, wishart, replicate_point);

  int icf_sz = d*(d + 1) / 2;
  int Jsz = (k*(d + 1)*(d + 2)) / 2;

  double e1, e2;
  vector<double> J(Jsz);

  high_resolution_clock::time_point start, end;
  double tf, tb = 0., tdv = 0.;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    gmm_objective(d, k, n, alphas.data(), means.data(),
      icf.data(), x.data(), wishart, &e1);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;
  cout << "err: " << e1 << endl;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_J; i++)
  {
    compute_gmm_Jb(d, k, n, alphas.data(),
      means.data(), icf.data(), x.data(), wishart, e2, J.data());
  }
  end = high_resolution_clock::now();
  tb = duration_cast<duration<double>>(end - start).count() / nruns_J;
  cout << "err: " << e2 << endl;

  /////////////////// results //////////////////////////
#if defined DO_GMM_FULL
  string name("Tapenade");
#elif defined DO_GMM_SPLIT
  string name("Tapenade_split");
#endif
  write_J(fn_out + "_J_" + name + ".txt", 1, Jsz, J.data());
  //write_times(tf, tb);
  write_times(fn_out + "_times_" + name + ".txt", tf, tb);
}

#elif defined DO_BA

void compute_reproj_error_Jbv_block(double* cam, double* X,
  double w, double *feat, double *err, double *J)
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
    feat[0], feat[1], err, errb, NB_DIRS_REPROJ_BV);

  for (int i = 0; i < 2; i++)
  {
    for (int j = 0; j < BA_NCAMPARAMS; j++)
      J[j * 2 + i] = camb[j][i];

    int off = BA_NCAMPARAMS * 2;
    for (int j = 0; j < 3; j++)
      J[j * 2 + i + off] = Xb[j][i];

    off += 3 * 2;
    J[i + off] = wb[i];
  }
}

void compute_ba_Jbv(int n, int m, int p, double *cams, double *X,
  double *w, int *obs, double *feats, double *reproj_err,
  double *w_err, BASparseMat& J)
{
  J = BASparseMat(n, m, p);

  int n_new_cols = BA_NCAMPARAMS + 3 + 1;
  vector<double> reproj_err_d(2 * n_new_cols);
  for (int i = 0; i < p; i++)
  {
    memset(reproj_err_d.data(), 0, 2 * n_new_cols*sizeof(double));

    int camIdx = obs[2 * i + 0];
    int ptIdx = obs[2 * i + 1];
    compute_reproj_error_Jbv_block(
      &cams[BA_NCAMPARAMS*camIdx],
      &X[ptIdx * 3],
      w[i],
      &feats[2 * i],
      &reproj_err[2 * i],
      reproj_err_d.data());

    J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
  }

  for (int i = 0; i < p; i++)
  {
    double err_b = 1.;
    double w_b = 0.;
    computeZachWeightError_b(&w[i], &w_b, &w_err[i], &err_b);

    J.insert_w_err_block(i, w_b);
  }
}

void test_ba(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J)
{
  int n, m, p;
  vector<double> cams, X, w, feats;
  vector<int> obs;

  //read instance
  read_ba_instance(fn_in + ".txt", n, m, p,
    cams, X, w, obs, feats);

  vector<double> reproj_err(2 * p);
  vector<double> w_err(p);
  BASparseMat J(n,m,p);

  high_resolution_clock::time_point start, end;
  double tf = 0., tJ = 0.;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    ba_objective(n, m, p, cams.data(), X.data(), w.data(),
      obs.data(), feats.data(), reproj_err.data(), w_err.data());
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_J; i++)
  {
    compute_ba_Jbv(n, m, p, cams.data(), X.data(), w.data(), 
      obs.data(), feats.data(), reproj_err.data(), w_err.data(), J);
  }
  end = high_resolution_clock::now();
  tJ = duration_cast<duration<double>>(end - start).count() / nruns_J;

  string name = "Tapenade";

  //write_J_sparse(fn_out + "_J_" + name + ".txt", J);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

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
#elif defined DO_BA
  test_ba(dir_in + fn, dir_out + fn, nruns_f, nruns_J);
#endif
}
