#ifndef TEST_UTILS
#define TEST_UTILS

#pragma warning (disable : 4996) // fopen

#include <iostream>
#include <string>
#include <vector>
#include <fstream>

#include "defs.h"

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
typedef struct
{
  int nrows, ncols;
  vector<int> rows;
  vector<int> cols;
  vector<double> vals;
} SparseMat;

void read_gmm_instance(const string& fn,
  int& d, int& k, int& n, double*& alphas,
  double*& means, double*& icf,
  double*& x, Wishart& wishart)
{
  FILE *fid = fopen(fn.c_str(), "r");

  fscanf(fid, "%i %i %i", &d, &k, &n);

  int icf_sz = d*(d + 1) / 2;
  alphas = new double[k];
  means = new double[d * k];
  icf = new double[icf_sz * k];
  x = new double[d*n];

  for (int i = 0; i < k; i++)
  {
    fscanf(fid, "%lf", &alphas[i]);
  }

  for (int i = 0; i < k; i++)
  {
    for (int j = 0; j < d; j++)
    {
      fscanf(fid, "%lf", &means[i*d + j]);
    }
  }

  for (int i = 0; i < k; i++)
  {
    for (int j = 0; j < icf_sz; j++)
    {
      fscanf(fid, "%lf", &icf[i*icf_sz + j]);
    }
  }

  for (int i = 0; i < n; i++)
  {
    for (int j = 0; j < d; j++)
    {
      fscanf(fid, "%lf", &x[i*d + j]);
    }
  }

  fscanf(fid, "%lf %i", &(wishart.gamma), &(wishart.m));

  fclose(fid);
}

void read_ba_instance(const string& fn, int& n, int& m, int& p,
  double*& cams, double*& X, double*& w, int*& obs, double*& feats)
{
  FILE *fid = fopen(fn.c_str(), "r");

  fscanf(fid, "%i %i %i", &n, &m, &p);
  int nCamParams = 11;

  cams = new double[nCamParams * n];
  X = new double[3 * m];
  w = new double[p];
  obs = new int[2 * p];
  feats = new double[2 * p];

  for (int i = 0; i < n; i++)
  {
    for (int j = 0; j < nCamParams; j++)
    {
      fscanf(fid, "%lf", &cams[i * nCamParams + j]);
    }
  }

  for (int i = 0; i < m; i++)
  {
    for (int j = 0; j < 3; j++)
    {
      fscanf(fid, "%lf", &X[i * 3 + j]);
    }
  }

  for (int i = 0; i < p; i++)
  {
    fscanf(fid, "%lf", &w[i]);
  }

  for (int i = 0; i < p; i++)
  {
    fscanf(fid, "%i %i", &obs[i * 2 + 0], &obs[i * 2 + 1]);
  }

  for (int i = 0; i < p; i++)
  {
    fscanf(fid, "%lf %lf", &feats[i * 2 + 0], &feats[i * 2 + 1]);
  }

  fclose(fid);
}

void write_J_sparse(const string& fn, SparseMat& J)
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
