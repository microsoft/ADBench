#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <cassert>


/*#ifdef DO_EIGEN
#define DO_HAND
#define DO_HAND_COMPLICATED
#endif*/

#include "../cpp-common/utils.h"
#include "../cpp-common/defs.h"

#ifdef DO_GMM
#include "../cpp-common/gmm.h"
#include "gmm_d.h"
#endif

#if defined DO_BA
#include "../cpp-common/ba.h"
#include "ba_d.h"
#endif

#if (defined DO_HAND || defined DO_HAND_COMPLICATED)
#ifdef DO_EIGEN
#include "../cpp-common/hand_eigen.h"
#include "hand_eigen_d.h"
#else
#include "../cpp-common/hand_light_matrix.h"
#endif
#endif

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

#ifdef DO_GMM
void test_gmm(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit, bool replicate_point)
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
  double tf = timer([&]() {
	  gmm_objective(d, k, n, alphas.data(), means.data(),
		  icf.data(), x.data(), wishart, &err);
  }, nruns_f, time_limit);
  cout << "err: " << err << endl;

  double tJ = timer([&]() {
	  gmm_objective_d(d, k, n, alphas.data(), means.data(),
		  icf.data(), x.data(), wishart, &err, J.data());
  }, nruns_J, time_limit);
  cout << "err: " << err << endl;

#ifdef DO_CPP
  string name("manual");
#elif defined DO_EIGEN
  string name("manual_eigen");
#elif defined DO_EIGEN_VECTOR
  string name("manual_eigen_vector");
#else
  string name("manual");
#endif
  write_J(fn_out + "_J_" + name + ".txt", Jrows, Jcols, J.data());
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}
#endif

#if defined DO_BA
void compute_ba_J(int n, int m, int p, double *cams, double *X,
  double *w, int *obs, double *feats, double *reproj_err,
  double *w_err, BASparseMat& J)
{
  J = BASparseMat(n,m,p);

  int n_new_cols = BA_NCAMPARAMS + 3 + 1;
  vector<double> reproj_err_d(2 * n_new_cols);
  for (int i = 0; i < p; i++)
  {
    memset(reproj_err_d.data(), 0, 2 * n_new_cols*sizeof(double));

    int camIdx = obs[2 * i + 0];
    int ptIdx = obs[2 * i + 1];
    computeReprojError_d(
      &cams[BA_NCAMPARAMS*camIdx], 
      &X[ptIdx * 3], 
      w[i], 
      feats[2 * i + 0], feats[2 * i + 1],
      &reproj_err[2 * i], 
      reproj_err_d.data());

    J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
  }

  for (int i = 0; i < p; i++)
  {
    double w_d = 0;
    computeZachWeightError_d(w[i], &w_err[i], &w_d);

    J.insert_w_err_block(i, w_d);
  }
}

void test_ba(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit)
{
  int n, m, p;
  vector<double> cams, X, w, feats;
  vector<int> obs;

  read_ba_instance(fn_in + ".txt", n, m, p,
    cams, X, w, obs, feats);

  vector<double> reproj_err(2 * p);
  vector<double> w_err(p);
  BASparseMat J(n,m,p);

  double tf = timer([&]() {
	  ba_objective(n, m, p, cams.data(), X.data(), w.data(),
		  obs.data(), feats.data(), reproj_err.data(), w_err.data());
  }, nruns_f, time_limit);

  double tJ = timer([&]() {
	  compute_ba_J(n, m, p, cams.data(), X.data(), w.data(), obs.data(),
		  feats.data(), reproj_err.data(), w_err.data(), J);
  }, nruns_J, time_limit);

#ifdef DO_EIGEN
  string name("manual_eigen");
#else
  string name("manual");
#endif
  write_J_sparse(fn_out + "_J_" + name + ".txt", J);
  write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#endif

#if defined DO_HAND
void test_hand(const string& model_dir, const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit)
{
  vector<double> theta;
#ifdef DO_EIGEN
  HandDataEigen data;
#else
  HandDataLightMatrix data;
#endif

  read_hand_instance(model_dir, fn_in + ".txt", &theta, &data);

  vector<double> err(3 * data.correspondences.size());
  vector<double> J(err.size() * theta.size());

  double tf = timer([&]() {
	  hand_objective(&theta[0], data, &err[0]);
  }, nruns_f, time_limit);

  double tJ = timer([&]() {
	  hand_objective_d(&theta[0], data, &err[0], &J[0]);
  }, nruns_J, time_limit);

#ifdef DO_EIGEN
  string name = "manual_eigen";
#else
  string name = "manual";
#endif

  write_J(fn_out + "_J_" + name + ".txt", (int)err.size(), (int)theta.size(), &J[0]);
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#elif defined DO_HAND_COMPLICATED
void test_hand(const string& model_dir, const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, double time_limit)
{
  vector<double> theta, us;
#ifdef DO_EIGEN
  HandDataEigen data;
#else
  HandDataLightMatrix data;
#endif

  read_hand_instance(model_dir, fn_in + ".txt", &theta, &data, &us);

  vector<double> err(3 * data.correspondences.size());
  vector<double> J(err.size() * (2+theta.size()));

  double tf = timer([&]() {
	  hand_objective(&theta[0], &us[0], data, &err[0]);
  }, nruns_f, time_limit);

  double tJ = timer([&]() {
	  hand_objective_d(&theta[0], &us[0], data, &err[0], &J[0]);
  }, nruns_J, time_limit);

#ifdef DO_EIGEN
  string name = "manual_eigen";
#else
  string name = "manual";
#endif

  write_J(fn_out + "_J_" + name + ".txt", (int)err.size(), 2+(int)theta.size(), &J[0]);
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#endif

char* defaults[] = {
	"",
	"../../../",
	"../../../tmpp/",
	"test",
#ifdef _NDEBUG
	"100",
	"100"
#else
	"2",
	"2"
#endif
};

int main(int argc, char *argv[])
{
	if (argc < 2) {
		argc = 6;
		argv = defaults;
	}
	else if (argc < 6) {
		std::cerr << "usage: Manual dir_in dir_out file_basename nruns_F nruns_J [-rep]\n";
		return 1;
	}

	string dir_in(argv[1]);
	string dir_out(argv[2]);
	string fn(argv[3]);
	int nruns_f = std::stoi(string(argv[4]));
    int nruns_J = std::stoi(string(argv[5]));
	double time_limit;
	if (argc >= 7) time_limit = std::stod(string(argv[6]));
	else time_limit = std::numeric_limits<double>::infinity();

  // read only 1 point and replicate it?
  bool replicate_point = (argc > 6 && string(argv[6]).compare("-rep") == 0);

#ifdef DO_GMM
  test_gmm(dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit, replicate_point);
#endif

#if defined DO_BA
  test_ba(dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit);
#endif

#if defined DO_HAND || defined DO_HAND_COMPLICATED
  test_hand(dir_in + "model/", dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit);
#endif
}
