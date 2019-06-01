#include <iostream>
#include <string>
#include <fstream>
#include <cassert>
#include <cstdint>

#include "../cpp-common/utils.h"
#include "../cpp-common/defs.h"

#include "../cpp-common/gmm.h"

#ifdef _WIN32
  #include <io.h>
  #include <fcntl.h>
#endif

using std::cout;
using std::cerr;
using std::endl;
using std::string;

template<typename T>
void write_futhark_value(const char *type, char num_dims, int64_t *dims, T* data) {
  cout << 'b';
  char version = 2;
  cout.write(&version, 1);
  cout.write(&num_dims, 1);
  cout.write(type, 4);
  int64_t num_elems = 1;
  for (int i = 0; i < num_dims; i++) {
    cout.write((const char*) &dims[i], sizeof(int64_t));
    num_elems *= dims[i];
  }
  cout.write((const char*)data, sizeof(T) * num_elems);
}

int main(int argc, const char *argv[])
{
  if (argc != 2) {
    cerr << "usage: " << argv[0] << " file" << endl;
    return 1;
  }

  string file(argv[1]);

  int d, k, n;
  vector<double> alphas, means, icf, x;
  double err;
  Wishart wishart;

  read_gmm_instance(file, &d, &k, &n, alphas, means, icf, x, wishart, false);

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

  preprocess_qs(d, k, &icf[0], &sum_qs[0], &Qdiags[0]);

  // Knossos GMM code expects the qs to be not exped
  for (double &q: Qdiags) q = log(q);

#ifdef _WIN32
  setmode(fileno(stdout),O_BINARY);
#endif

  int triD = ls.size() / k;

  int64_t x_dims[] = {n, d};
  write_futhark_value<double>(" f64", 2, x_dims, &*x.begin());
  int64_t alphas_dims[] = {k};
  write_futhark_value<double>(" f64", 1, alphas_dims, &*alphas.begin());
  int64_t means_dims[] = {k, d};
  write_futhark_value<double>(" f64", 2, means_dims, &*means.begin());
  int64_t Qdiags_dims[] = {k, d};
  write_futhark_value<double>(" f64", 2, Qdiags_dims, &*Qdiags.begin());
  int64_t ls_dims[] = {k, triD};
  write_futhark_value<double>(" f64", 2, ls_dims, &*ls.begin());
  write_futhark_value<double>(" f64", 0, NULL, &wishart.gamma);
  write_futhark_value<int32_t>(" i32", 0, NULL, &wishart.m);
  double d_r = 1;
  write_futhark_value<double>(" f64", 0, NULL, &d_r);
}
