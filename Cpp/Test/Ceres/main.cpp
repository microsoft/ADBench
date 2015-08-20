#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <vector>

#include "ceres/ceres.h"
#include "../utils.h"
#include "gmm.h"
#include "ba.h"

#define GMM_D 10
#define GMM_K 25
#define GMM_ICF_DIM (GMM_D*(GMM_D + 1) / 2)

using ceres::AutoDiffCostFunction;
using ceres::CostFunction;
using ceres::Problem;
using ceres::Solver;
using ceres::Solve;

using std::cout;
using std::endl;
using std::string;
using std::vector;
using namespace std::chrono;

void write_J_sparse(const string& fn, ceres::CRSMatrix& J);
void convert_gmm_J(int d, int k, double **J_ceres, double **J);

struct GMMCostFunctor {
  GMMCostFunctor(int n,
    const double* const x, Wishart wishart) :
    n_(n), x_(x), wishart_(wishart) {}

  template <typename T> bool operator()(const T* const alphas,
    const T* const means, const T* const icf, T* err) const
  {
    gmm_objective(GMM_D, GMM_K, n_, alphas,
      means, icf, x_, wishart_, err);
    return true;
  }

private:
  int n_;
  const double* const x_;
  Wishart wishart_;
};

void compute_gmm_J(int d, int k, int n, double *alphas,
  double *means, double *icf, double *x, Wishart wishart,
  double& err, double **J)
{
  CostFunction* cost_function =
    new AutoDiffCostFunction<GMMCostFunctor, 1, GMM_K, GMM_D*GMM_K,
    GMM_ICF_DIM*GMM_K>(new GMMCostFunctor(n, x, wishart));

  double *params[3];
  params[0] = alphas;
  params[1] = means;
  params[2] = icf;
  cost_function->Evaluate(params, &err, J);
}

int test_gmm(const string& fn, int nruns_f, int nruns_J)
{
  int d, k, n;
  double *alphas, *means, *icf, *x;
  Wishart wishart;
  double err;

  // Read instance
  read_gmm_instance(fn + ".txt", d, k, n,
    alphas, means, icf, x, wishart);

  if (d != GMM_D || k != GMM_K)
  {
    cout << "test_gmm: error: d and K in the specified file do not match with defines GMM_D and GMM_K"
      << endl;
    return -1;
  }

  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  double **J = new double*[Jrows];
  for (int i = 0; i < Jrows; i++)
  {
    J[i] = new double[Jcols];
  }
  double **J_ceres = new double*[3];
  J_ceres[0] = new double[k];
  J_ceres[1] = new double[d*k];
  J_ceres[2] = new double[GMM_ICF_DIM*k];

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

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_J; i++)
  {
    compute_gmm_J(d, k, n, alphas,
      means, icf, x, wishart, err, J_ceres);
  }
  end = high_resolution_clock::now();
  tJ = duration_cast<duration<double>>(end - start).count() / nruns_J;

  convert_gmm_J(d, k, J_ceres, J);
  write_J(fn + "J_Ceres.txt", Jrows, Jcols, J);
  //write_times(tf, tJ);
  write_times(fn + "J_Ceres_times.txt", tf, tJ);

  for (int i = 0; i < 3; i++)
  {
    delete[] J_ceres[i];
  }
  delete[] J_ceres;
  for (int i = 0; i < Jrows; i++)
  {
    delete[] J[i];
  }
  delete[] J;
  delete[] alphas;
  delete[] means;
  delete[] icf;
  return 0;
}

struct ReprojectionError {
  ReprojectionError(double feat_x, double feat_y)
    : feat_x_(feat_x), feat_y_(feat_y) {}

  template <typename T>
  bool operator()(const T* const camera,
    const T* const point, const T* const w,
    T* residuals) const
  {
    computeReprojError(camera, point, w,
      feat_x_, feat_y_, residuals);
    return true;
  }

  static ceres::CostFunction* create(const double feat_x,
    const double feat_y) {
    return (new ceres::AutoDiffCostFunction
      <ReprojectionError, 2, BA_NCAMPARAMS, 3, 1>(
        new ReprojectionError(feat_x, feat_y)));
  }

  double feat_x_;
  double feat_y_;
};

struct FocalPriorError {
  template <typename T>
  bool operator()(const T* const cam1,
    const T* const cam2, const T* const cam3,
    T* err) const
  {
    computeFocalPriorError(cam1, cam2, cam3, err);
    return true;
  }

  static ceres::CostFunction* create() {
    return (new ceres::AutoDiffCostFunction
      <FocalPriorError, 1, BA_NCAMPARAMS,
      BA_NCAMPARAMS, BA_NCAMPARAMS>(
        new FocalPriorError));
  }
};

struct ZachWeightError {
  template <typename T>
  bool operator()(const T* const w, T* err) const
  {
    computeZachWeightError(w, err);
    return true;
  }

  static ceres::CostFunction* create() {
    return (new ceres::AutoDiffCostFunction
      <ZachWeightError, 1, 1>(
        new ZachWeightError));
  }
};

void compute_ba_J(int n, int m, int p, double *cams,
  double *X, double *w, int *obs, double *feats,
  double *reproj_err, double *f_prior_err,
  double *w_err, ceres::CRSMatrix& J)
{
  Problem problem;

  for (int i = 0; i < n; i++)
  {
    problem.AddParameterBlock(&cams[i * BA_NCAMPARAMS], BA_NCAMPARAMS);
  }
  for (int i = 0; i < m; i++)
  {
    problem.AddParameterBlock(&X[i * 3], 3);
  }
  for (int i = 0; i < p; i++)
  {
    problem.AddParameterBlock(&w[i], 1);
  }

  for (int i = 0; i < p; ++i)
  {
    int camIdx = obs[2 * i + 0];
    int ptIdx = obs[2 * i + 1];
    problem.AddResidualBlock(
      ReprojectionError::create(
        feats[2 * i + 0],
        feats[2 * i + 1]),
      nullptr,
      &cams[BA_NCAMPARAMS*camIdx],
      &X[3 * ptIdx],
      &w[i]);
  }
  for (int i = 0; i < n - 2; i++)
  {
    int idx1 = BA_NCAMPARAMS * i;
    int idx2 = BA_NCAMPARAMS * (i + 1);
    int idx3 = BA_NCAMPARAMS * (i + 2);
    problem.AddResidualBlock(FocalPriorError::create(),
      nullptr,
      &cams[idx1],
      &cams[idx2],
      &cams[idx3]);
  }
  for (int i = 0; i < p; i++)
  {
    problem.AddResidualBlock(ZachWeightError::create(),
      nullptr, &w[i]);
  }

  vector<double> residuals;
  ceres::Problem::EvaluateOptions opt;
  problem.Evaluate(opt, nullptr, &residuals, nullptr, &J);
}

void test_ba(const string& fn, int nruns)
{
  int n, m, p;
  double *cams, *X, *w, *feats;
  int *obs;

  //read instance
  read_ba_instance(fn + ".txt", n, m, p,
    cams, X, w, obs, feats);

  ceres::CRSMatrix J;
  double *reproj_err = new double[2 * p];
  double *f_prior_err = new double[n - 2];
  double *w_err = new double[p];

  high_resolution_clock::time_point start, end;
  double tf, tJ;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    ba_objective(n, m, p, cams, X, w, obs,
      feats, reproj_err, f_prior_err, w_err);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    compute_ba_J(n, m, p, cams, X, w, obs, feats,
      reproj_err, f_prior_err, w_err, J);
  }
  end = high_resolution_clock::now();
  tJ = duration_cast<duration<double>>(end - start).count() / nruns;

  write_J_sparse(fn + "J_Ceres.txt", J);

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

int main(int argc, char** argv)
{
  string fn(argv[1]);
  int nruns_f = 1;
  int nruns_J = 1;
  if (argc >= 3)
  {
    nruns_f = std::stoi(string(argv[2]));
    nruns_J = std::stoi(string(argv[3]));
  }
  //google::InitGoogleLogging(argv[0]);
  return test_gmm(fn, nruns_f, nruns_J);
  //test_ba(fn, nruns); return 0;
}

void write_J_sparse(const string& fn, ceres::CRSMatrix& J)
{
  SparseMat Jnew;
  Jnew.nrows = J.num_rows;
  Jnew.ncols = J.num_cols;
  Jnew.rows = J.rows;
  Jnew.cols = J.cols;
  Jnew.vals = J.values;
  write_J_sparse(fn, Jnew);
}

void convert_gmm_J(int d, int k, double **J_ceres, double **J)
{
  int icf_sz = d*(d + 1) / 2;
  memcpy(J[0], J_ceres[0], k*sizeof(double));
  int J_off = k;
  memcpy(J[0] + J_off, J_ceres[1], d*k*sizeof(double));
  J_off += d*k;
  memcpy(J[0] + J_off, J_ceres[2], icf_sz*k*sizeof(double));
}