#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <cassert>

#include "../cpp-common/utils.h"
#include "../cpp-common/defs.h"

#include "../cpp-common/gmm.h"

extern "C" {
#include "gmm_wrapper.h"
}

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

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

  // Knossos GMM code expects the qs to be not exped
  for (double &q: Qdiags) q = log(q);

  auto cfg = futhark_context_config_new();
  auto ctx = futhark_context_new(cfg);

  int triD = ls.size() / k;

  auto alphas_fut = futhark_new_f64_1d(ctx, &*alphas.begin(), k);
  auto x_fut = futhark_new_f64_2d(ctx, &*x.begin(), n, d);
  auto means_fut = futhark_new_f64_2d(ctx, &*means.begin(), k, d);
  auto Qdiags_fut = futhark_new_f64_2d(ctx, &*Qdiags.begin(), k, d);
  auto ls_fut = futhark_new_f64_2d(ctx, &*ls.begin(), k, triD);

  // Test
  double tf = timer(
                    nruns_f,
                    time_limit,
                    [&]() {
                      futhark_entry_gmm_objective(ctx,
                                                  &err,
                                                  x_fut,
                                                  alphas_fut,
                                                  means_fut,
                                                  Qdiags_fut,
                                                  ls_fut,
                                                  wishart.gamma, wishart.m);
                    });
  cout << "err: " << err << endl;

  double tJ = timer(nruns_J, time_limit, [&]() {
                                           struct futhark_f64_1d *b;
                                           struct futhark_f64_2d *c;
                                           struct futhark_f64_2d *d;
                                           struct futhark_f64_2d *e;
                                           futhark_entry_rev_gmm_objective(ctx,
                                                                           &b, &c, &d, &e,
                                                                           x_fut,
                                                                           alphas_fut,
                                                                           means_fut,
                                                                           Qdiags_fut,
                                                                           ls_fut,
                                                                           wishart.gamma, wishart.m,
                                                                           1.0);
                                           futhark_context_sync(ctx);
                                           futhark_free_f64_1d(ctx, b);
                                           futhark_free_f64_2d(ctx, c);
                                           futhark_free_f64_2d(ctx, d);
                                           futhark_free_f64_2d(ctx, e);
                                         });

  string name("KnossosFuthark");

  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

const char* defaults[] = {
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

int main(int argc, const char *argv[])
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

  test_gmm(dir_in + fn, dir_out + fn, nruns_f, nruns_J, time_limit, replicate_point);
}
