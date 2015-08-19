#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <cassert>

#include "../utils.h"
#include "../defs.h"
#include "gmm.h"
#include "ba.h"

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

void test_gmm(const string& fn, int nruns_f, int nruns_J)
{
  int d, k, n;
  double *alphas, *means, *icf, *x;
  double err;
  Wishart wishart;

  // Read instance
  read_gmm_instance(fn + ".txt", d, k, n,
    alphas, means, icf, x, wishart);

  int icf_sz = d*(d + 1) / 2;
  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  double *J = new double[Jcols];

  // Test
  high_resolution_clock::time_point start, end;
  double tf, tJ = 0.;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    gmm_objective(d, k, n, alphas, means,
      icf, x, wishart, &err);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;
  cout << "err: " << err << endl;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_J; i++)
  {
    gmm_objective_d(d, k, n, alphas, means,
      icf, x, wishart, &err, J);
  }
  end = high_resolution_clock::now();
  tJ = duration_cast<duration<double>>(end - start).count() / nruns_J;

  string name = "J_manual";
  //string name = "J_manual_VS";
  //string name = "J_manual_Intel";
  //string name = "J_manual_Eigen5";
  //string name = "J_manual_Eigen4_VS";
  write_J(fn + name + ".txt", Jrows, Jcols, J);
  //write_times(tf, tJ);
  write_times(fn + name + "_times.txt", tf, tJ);

  delete[] J;
  delete[] alphas;
  delete[] means;
  delete[] x;
  delete[] icf;
}


void compute_reproj_error_J_block(int n, int m, int obsIdx,
  int camIdx, int ptIdx, double *cam, double *X, double w,
  double *feat, double *reproj_err, SparseMat& J)
{
  int n_new_cols = BA_NCAMPARAMS + 3 + 1;
  double *Jall = new double[2 * n_new_cols];
  computeReprojError_d(cam, X, w, feat[0], feat[1],
    reproj_err, Jall);

  J.rows.push_back(J.rows.back() + n_new_cols);
  J.rows.push_back(J.rows.back() + n_new_cols);

  for (int i_row = 0; i_row < 2; i_row++)
  {
    for (int i = 0; i < BA_NCAMPARAMS; i++)
    {
      J.cols.push_back(BA_NCAMPARAMS*camIdx + i);
      J.vals.push_back(Jall[2 * i + i_row]);
    }
    int col_offset = BA_NCAMPARAMS*n;
    int val_offset = BA_NCAMPARAMS * 2;
    for (int i = 0; i < 3; i++)
    {
      J.cols.push_back(col_offset + 3 * ptIdx + i);
      J.vals.push_back(Jall[val_offset + 2 * i + i_row]);
    }
    col_offset += 3 * m;
    val_offset += 3 * 2;
    J.cols.push_back(col_offset + obsIdx);
    J.vals.push_back(Jall[val_offset + i_row]);
  }

  delete[] Jall;
}

void compute_f_prior_error_J_block(int cam1_idx,
  double f1, double f2, double f3,
  double *f_prior_err, SparseMat& J)
{
  double Jf[3];
  computeFocalPriorError_d(f1, f2,
    f3, f_prior_err, Jf);

  int n_new_cols = 3;
  J.rows.push_back(J.rows.back() + n_new_cols);

  for (int i = 0; i < 3; i++)
  {
    int col_idx = (cam1_idx + i)* BA_NCAMPARAMS + BA_F_IDX;
    J.cols.push_back(col_idx);
    J.vals.push_back(Jf[i]);
  }
}

void compute_w_error_J_block(int n,
  int m, int wIdx, double w,
  double *w_err, SparseMat& J)
{
  double w_d;
  computeZachWeightError_d(w, w_err, &w_d);

  J.rows.push_back(J.rows.back() + 1);
  J.cols.push_back(BA_NCAMPARAMS*n + 3 * m + wIdx);
  J.vals.push_back(w_d);
}

void compute_ba_J(int n, int m, int p, double *cams, double *X,
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
    compute_reproj_error_J_block(n, m, i, camIdx, ptIdx,
      &cams[BA_NCAMPARAMS*camIdx], &X[ptIdx * 3],
      w[i], &feats[2 * i], &reproj_err[2 * i], J);
  }

  for (int i = 0; i < n - 2; i++)
  {
    int idx1 = BA_NCAMPARAMS * i + BA_F_IDX;
    int idx2 = BA_NCAMPARAMS * (i + 1) + BA_F_IDX;
    int idx3 = BA_NCAMPARAMS * (i + 2) + BA_F_IDX;
    compute_f_prior_error_J_block(i,
      cams[idx1], cams[idx2], cams[idx3],
      &f_prior_err[i], J);
  }

  for (int i = 0; i < p; i++)
  {
    compute_w_error_J_block(n, m, i, w[i], &w_err[i], J);
  }
}

void test_ba(const string& fn, int nruns)
{
  int n, m, p;
  double *cams, *X, *w, *feats;
  int *obs;

  //read instance
  read_ba_instance(fn + ".txt", n, m, p,
    cams, X, w, obs, feats);

  double *reproj_err = new double[2 * p];
  double *f_prior_err = new double[n - 2];
  double *w_err = new double[p];
  SparseMat J;

  high_resolution_clock::time_point start, end;
  double tf, tJ = 0;

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
  compute_ba_J(n, m, p, cams, X, w, obs, feats,
  reproj_err, f_prior_err, w_err, J);
  }
  end = high_resolution_clock::now();
  tJ = duration_cast<duration<double>>(end - start).count() / nruns;

  write_J_sparse(fn + "J_manual.txt", J);*/
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
  string fn(argv[1]);
  int nruns_f = 1;
  int nruns_J = 1;
  if (argc >= 3)
  {
    nruns_f = std::stoi(string(argv[2]));
    nruns_J = std::stoi(string(argv[3]));
  }
  test_gmm(fn, nruns_f, nruns_J);
  //test_ba(fn, nruns);
}