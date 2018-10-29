// This file was created by taking Manual/main.cpp and hacking it
// about until it supported the Coconut GMM example

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

extern "C" {
// Ideally these would be in a header file.  However, I had problems
// using the types array_number_t and array_array_number_t from C++
// code so I used void* instead.  The function definitions in
// marshal.c use the correct type.

double run_gmm(int n,
               int k,
               int d,
               int l_sz,
               void *x,
               void *alphas,
               void *means,
               void *qs,
               void *ls,
               double wishart_gamma_dps,
               double wishart_m_dps,
               double *err);

double extract_gmm(int n,
                   int k,
                   int d,
                   int l_sz,
                   const double *x,
                   const double *alphas,
                   const double *means,
                   const double *qs,
                   const double *ls,
                   void **xc,
                   void **alphasc,
                   void **meansc,
                   void **qsc,
                   void **lsc);
}

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

  // We don't actually care about this but we have to pass something to preprocess_qs
  vector<double> sum_qs(k);
  vector<double> Qdiags(d*k);

  auto l_sz = d * (d - 1) / 2;

  vector<double> ls(l_sz * k);

  int lsi = 0;
  int lcfi = 0;
  for (int ik = 0; ik < k; ik++) {
    // Skip over the qs
    lcfi += d;
    for (int il = 0; il < l_sz; il++) {
      ls[lsi] = icf[lcfi];
      lsi++;
      lcfi++;
    }
  }                    

  preprocess_qs(d, k, &icf[0], &sum_qs[0], &Qdiags[0]);

  // Amir's F~ GMM code expects the qs to be not exped
  for (double &q: Qdiags) q = log(q);

  void *xc;
  void *alphasc;
  void *meansc;
  void *qsc;
  void *lsc;

  extract_gmm(n,
              k,
              d,
              l_sz,
              x.data(),
              alphas.data(),
              means.data(),
              Qdiags.data(),
              ls.data(),
              &xc,
              &alphasc,
              &meansc,
              &qsc,
              &lsc);

  // Test
  double tf = timer(
      nruns_f,
      time_limit,
      [&]() {
      run_gmm(n,
              k,
              d,
              l_sz,
              xc,
              alphasc,
              meansc,
              qsc,
              lsc,
              wishart.gamma,
              wishart.m,
              &err);
  });
  cout << "err: " << err << endl;

  string name("coconut");
  double tJ(1);

  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}
#endif

char* defaults[] = {
	"",
	"../../data/gmm/",
	"../../tmp",
	"test",
#ifdef _NDEBUG
	"100",
	"100"
#else
	"1000000",
	"1000000"
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
}
