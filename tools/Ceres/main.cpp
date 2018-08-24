#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <vector>

//#define DO_GMM
//#define DO_BA
#define DO_HAND

//#define DO_CPP
//#define DO_EIGEN
#define DO_LIGHT_MATRIX

#include "ceres/ceres.h"
#include "../cpp-common/utils.h"

#if defined DO_GMM
#include "gmm.h"

#ifndef GMM_D
#define GMM_D 2
#endif

#ifndef GMM_K
#define GMM_K 5
#endif

#define GMM_ICF_DIM (GMM_D*(GMM_D + 1) / 2)
#elif defined DO_BA
#include "ba.h"

#elif defined DO_HAND
#ifdef DO_EIGEN
#include "hand_eigen.h"
typedef HandDataEigen HandDataType;
#elif defined DO_LIGHT_MATRIX
#include "hand_light_matrix.h"
typedef HandDataLightMatrix HandDataType;
#endif
#define HAND_PARAMS_DIM 26
#define HAND_NUM_PTS 100000
#endif

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

#ifdef DO_GMM

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

void convert_gmm_J(int d, int k, double **J_ceres, double *J)
{
  int icf_sz = d*(d + 1) / 2;
  memcpy(J, J_ceres[0], k*sizeof(double));
  int J_off = k;
  memcpy(J + J_off, J_ceres[1], d*k*sizeof(double));
  J_off += d*k;
  memcpy(J + J_off, J_ceres[2], icf_sz*k*sizeof(double));
}

void test_gmm(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit, bool replicate_point)
{
  int d, k, n;
  vector<double> alphas, means, icf, x;
  Wishart wishart;
  double err;

  // Read instance
  read_gmm_instance(fn_in + ".txt", &d, &k, &n,
    alphas, means, icf, x, wishart, replicate_point);

  if (d != GMM_D || k != GMM_K)
  {
    cout << "test_gmm: error: d and K in the specified file do not match with defines GMM_D and GMM_K"
      << endl;
    return;
  }

  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  double **J_ceres = new double*[3];
  J_ceres[0] = new double[k];
  J_ceres[1] = new double[d*k];
  J_ceres[2] = new double[GMM_ICF_DIM*k];

  // Test
  double tf = timer(nruns_f, time_limit, [&]() {
	  gmm_objective(d, k, n, alphas.data(), means.data(),
		  icf.data(), x.data(), wishart, &err);
  });

  double tJ = timer(nruns_J, time_limit, [&]() {
	  compute_gmm_J(d, k, n, alphas.data(),
		  means.data(), icf.data(), x.data(), wishart, err, J_ceres);
  });

  string name("Ceres");
  vector<double> J(Jcols);
  convert_gmm_J(d, k, J_ceres, J.data());
  write_J(fn_out + "_J_" + name + ".txt", Jrows, Jcols, J.data());
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);

  for (int i = 0; i < 3; i++)
  {
    delete[] J_ceres[i];
  }
  delete[] J_ceres;
}

#elif defined DO_BA

struct ReprojectionError {
  ReprojectionError(const double* const feat)
    : feat_(feat) {}

  template <typename T>
  bool operator()(
    const T* const camera,
    const T* const point, 
    const T* const w,
    T* residuals) const
  {
    computeReprojError(camera, point, w,
      feat_, residuals);
    return true;
  }

  static ceres::CostFunction* create(const double* const feat) {
    return (new ceres::AutoDiffCostFunction
      <ReprojectionError, 2, BA_NCAMPARAMS, 3, 1>(
        new ReprojectionError(feat)));
  }

  const double* const feat_;
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
  double *reproj_err, double *w_err, ceres::CRSMatrix& J)
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
        &feats[2 * i]),
      nullptr,
      &cams[BA_NCAMPARAMS*camIdx],
      &X[3 * ptIdx],
      &w[i]);
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

void write_J_sparse(const string& fn, ceres::CRSMatrix& J)
{
  BASparseMat Jnew;
  Jnew.nrows = J.num_rows;
  Jnew.ncols = J.num_cols;
  Jnew.rows = J.rows;
  Jnew.cols = J.cols;
  Jnew.vals = J.values;
  write_J_sparse(fn, Jnew);
}

void test_ba(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit)
{
  int n, m, p;
  vector<double> cams, X, w, feats;
  vector<int> obs;

  read_ba_instance(fn_in + ".txt", n, m, p,
    cams, X, w, obs, feats);

  ceres::CRSMatrix J;
  vector<double> reproj_err(2 * p);
  vector<double> w_err(p);

  double tf = timer(nruns_f, time_limit, [&]() {
	  ba_objective(n, m, p, cams.data(), X.data(),
		  w.data(), obs.data(), feats.data(),
		  reproj_err.data(), w_err.data());
  });

  double tJ = timer(nruns_J, time_limit, [&]() {
	  compute_ba_J(n, m, p, cams.data(), X.data(), w.data(),
		  obs.data(), feats.data(), reproj_err.data(), w_err.data(), J);
  });

  string name = "Ceres";
  //write_J_sparse(fn_out + "_J_" + name + ".txt", J);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#elif defined DO_HAND
void convert_J(size_t n_rows, size_t n_cols, vector<double>& J_ceres, vector<double> *pJ)
{
  for (size_t i_row = 0; i_row < n_rows; i_row++)
    for (size_t i_col = 0; i_col < n_cols; i_col++)
      (*pJ)[i_col*n_rows + i_row] = J_ceres[i_row*n_cols + i_col];
}

struct HandCostFunctor {
  HandCostFunctor(const HandDataType& data) :
    data_(data) {}

  template <typename T> bool operator()(const T* const params, T* err) const
  {
    hand_objective(params, data_, err);
    return true;
  }

private:
  const HandDataType& data_;
};

void compute_hand_J(
  vector<double>& params,
  const HandDataType& data,
  vector<double> *perr,
  vector<double> *pJ)
{
  auto& err = *perr;
  vector<double> J_ceres(pJ->size());
  CostFunction *cost_function =
    new AutoDiffCostFunction<HandCostFunctor, 3 * HAND_NUM_PTS,
    HAND_PARAMS_DIM>(new HandCostFunctor(data));

  double *tmp_J = &J_ceres[0];
  double *tmp_params = &params[0];
  cost_function->Evaluate(&tmp_params, &err[0], &tmp_J);
  convert_J(err.size(), params.size(), J_ceres, pJ);
}

void test_hand(const string& model_dir, const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit)
{
  vector<double> params;
  HandDataType data;
  read_hand_instance(model_dir, fn_in + ".txt", &params, &data);

  vector<double> err(3 * data.correspondences.size());
  vector<double> J(err.size() * params.size(), 0);

  double tf = timer(nruns_f, time_limit, [&]() {
	  hand_objective(&params[0], data, &err[0]);
  });

  double tJ = timer(nruns_J, time_limit, [&]() {
	  compute_hand_J(params, data, &err, &J);
  });

#ifdef DO_EIGEN
  string name("Ceres_eigen");
#elif defined DO_LIGHT_MATRIX
  string name("Ceres_light");
#endif

  write_J(fn_out + "_J_" + name + ".txt", (int)err.size(), (int)params.size(), &J[0]);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#endif

int main(int argc, char** argv)
{
  string dir_in(argv[1]);
  string dir_out(argv[2]);
  string fn(argv[3]);
  int nruns_f = std::stoi(string(argv[4]));
  int nruns_J = std::stoi(string(argv[5]));
  double time_limit;
  if (argc >= 7) time_limit = std::stod(string(argv[6]));
  else time_limit = std::numeric_limits<double>::infinity();

  // read only 1 point and replicate it?
  bool replicate_point = (argc >= 7 && string(argv[6]).compare("-rep") == 0);

#ifdef DO_GMM
  test_gmm(dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit, replicate_point);
#elif defined DO_BA
  test_ba(dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit);
#elif defined DO_HAND
  test_hand(dir_in + "model/", dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit);
#endif
}