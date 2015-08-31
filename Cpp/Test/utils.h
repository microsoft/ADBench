#ifndef TEST_UTILS
#define TEST_UTILS

#pragma warning (disable : 4996) // fopen

#include <iostream>
#include <string>
#include <vector>
#include <fstream>

#include "../defs.h"

using std::cin;
using std::cout;
using std::endl;
using std::string;
using std::vector;

// rows is nrows+1 vector containing
// indices to cols and vals. 
// rows[i] ... rows[i+1]-1 are elements of i-th row
// i.e. cols[row[i]] is the column of the first
// element in the row. Similarly for values.
class BASparseMat
{
public:
  int n, m, p; // number of cams, points and observations
  int nrows, ncols;
  vector<int> rows;
  vector<int> cols;
  vector<double> vals;

  BASparseMat(int n_, int m_, int p_) : n(n_), m(m_), p(p_)
  {
    nrows = 2 * p + p;
    ncols = BA_NCAMPARAMS*n + 3 * m + p;
    rows.push_back(0);
  }

  void insert_reproj_err_block(int obsIdx, 
    int camIdx,int ptIdx,const double* const J)
  {
    int n_new_cols = BA_NCAMPARAMS + 3 + 1;
    rows.push_back(rows.back() + n_new_cols);
    rows.push_back(rows.back() + n_new_cols);

    for (int i_row = 0; i_row < 2; i_row++)
    {
      for (int i = 0; i < BA_NCAMPARAMS; i++)
      {
        cols.push_back(BA_NCAMPARAMS*camIdx + i);
        vals.push_back(J[2 * i + i_row]);
      }
      int col_offset = BA_NCAMPARAMS*n;
      int val_offset = BA_NCAMPARAMS * 2;
      for (int i = 0; i < 3; i++)
      {
        cols.push_back(col_offset + 3 * ptIdx + i);
        vals.push_back(J[val_offset + 2 * i + i_row]);
      }
      col_offset += 3 * m;
      val_offset += 3 * 2;
      cols.push_back(col_offset + obsIdx);
      vals.push_back(J[val_offset + i_row]);
    }
  }

  void insert_w_err_block(int wIdx, double w_d)
  {
    rows.push_back(rows.back() + 1);
    cols.push_back(BA_NCAMPARAMS*n + 3 * m + wIdx);
    vals.push_back(w_d);
  }
};

void read_gmm_instance(const string& fn,
  int *d, int *k, int *n, 
  vector<double>& alphas,
  vector<double>& means,
  vector<double>& icf,
  vector<double>& x,
  Wishart& wishart,
  bool replicate_point)
{
  FILE *fid = fopen(fn.c_str(), "r");

  fscanf(fid, "%i %i %i", d, k, n);

  int d_ = *d, k_ = *k, n_ = *n;

  int icf_sz = d_*(d_ + 1) / 2;
  alphas.resize(k_);
  means.resize(d_*k_);
  icf.resize(icf_sz*k_);
  x.resize(d_*n_);

  for (int i = 0; i < k_; i++)
  {
    fscanf(fid, "%lf", &alphas[i]);
  }

  for (int i = 0; i < k_; i++)
  {
    for (int j = 0; j < d_; j++)
    {
      fscanf(fid, "%lf", &means[i*d_ + j]);
    }
  }

  for (int i = 0; i < k_; i++)
  {
    for (int j = 0; j < icf_sz; j++)
    {
      fscanf(fid, "%lf", &icf[i*icf_sz + j]);
    }
  }

  if (replicate_point)
  {
    for (int j = 0; j < d_; j++)
    {
      fscanf(fid, "%lf", &x[j]);
    }
    for (int i = 0; i < n_; i++)
    {
      memcpy(&x[i*d_], &x[0], d_ * sizeof(double));
    }
  }
  else
  {
    for (int i = 0; i < n_; i++)
    {
      for (int j = 0; j < d_; j++)
      {
        fscanf(fid, "%lf", &x[i*d_ + j]);
      }
    }
  }

  fscanf(fid, "%lf %i", &(wishart.gamma), &(wishart.m));

  fclose(fid);
}

void read_ba_instance(const string& fn, 
  int& n, int& m, int& p,
  vector<double>& cams, 
  vector<double>& X, 
  vector<double>& w, 
  vector<int>& obs, 
  vector<double>& feats)
{
  FILE *fid = fopen(fn.c_str(), "r");

  fscanf(fid, "%i %i %i", &n, &m, &p);
  int nCamParams = 11;

  cams.resize(nCamParams*n);
  X.resize(3*m);
  w.resize(p);
  obs.resize(2*p);
  feats.resize(2*p);

  for (int j = 0; j < nCamParams; j++)
    fscanf(fid, "%lf", &cams[j]);
  for (int i = 1; i < n; i++)
    memcpy(&cams[i*nCamParams], &cams[0], nCamParams*sizeof(double));

  for (int j = 0; j < 3; j++)
    fscanf(fid, "%lf", &X[j]);
  for (int i = 1; i < m; i++)
    memcpy(&X[i*3], &X[0], 3*sizeof(double));

  fscanf(fid, "%lf", &w[0]);
  for (int i = 1; i < p; i++)
    w[i] = w[0];

  int camIdx = 0;
  int ptIdx = 0;
  for (int i = 0; i < p; i++)
  {
    obs[i * 2 + 0] = (camIdx++ % n);
    obs[i * 2 + 1] = (ptIdx++ % m);
  }

  fscanf(fid, "%lf %lf", &feats[0], &feats[1]);
  for (int i = 1; i < p; i++)
  {
    feats[i * 2 + 0] = feats[0];
    feats[i * 2 + 1] = feats[1];
  }

  fclose(fid);
}

void write_J_sparse(const string& fn, const BASparseMat& J)
{
  std::ofstream out(fn);
  out << J.nrows << " " << J.ncols << endl;
  out << J.rows.size() << endl;
  for (size_t i = 0; i < J.rows.size(); i++)
  {
    out << J.rows[i] << " ";
  }
  out << endl;
  out << J.cols.size() << endl;
  for (size_t i = 0; i < J.cols.size(); i++)
  {
    out << J.cols[i] << " ";
  }
  out << endl;
  for (size_t i = 0; i < J.vals.size(); i++)
  {
    out << J.vals[i] << " ";
  }
  out.close();
}

void write_J(const string& fn, int Jrows, int Jcols, double **J)
{
  std::ofstream out(fn);
  out << Jrows << " " << Jcols << endl;
  for (int i = 0; i < Jrows; i++)
  {
    for (int j = 0; j < Jcols; j++)
    {
      out << J[i][j] << " ";
    }
    out << endl;
  }
  out.close();
}

void write_J(const string& fn, int Jrows, int Jcols, double *J)
{
  std::ofstream out(fn);
  out << Jrows << " " << Jcols << endl;
  for (int i = 0; i < Jrows; i++)
  {
    for (int j = 0; j < Jcols; j++)
    {
      out << J[j * Jrows + i] << " ";
    }
    out << endl;
  }
  out.close();
}

void write_times(double tf, double tJ)
{
  cout << "tf = " << std::scientific << tf << "s" << endl;
  cout << "tJ = " << tJ << "s" << endl;
  cout << "tJ/tf = " << tJ / tf << "s" << endl;
}

void write_times(const string& fn, double tf, double tJ)
{
  std::ofstream out(fn);
  out << std::scientific << tf << " " << tJ << endl;
  out << "tf tJ" << endl;
  out << "tf = " << std::scientific << tf << "s" << endl;
  out << "tJ = " << tJ << "s" << endl;
  out << "tJ/tf = " << tJ / tf << "s" << endl;
  out.close();
}

#endif
