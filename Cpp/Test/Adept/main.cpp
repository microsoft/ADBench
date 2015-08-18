#include <iostream>
#include <string>
#include <chrono>
#include <set>

#include "adept.h"
#include "../utils.h"
#include "../defs.h"
#define ADEPT_COMPILATION
#include "../ADOLC/gmm.h"

using adept::adouble;
using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

double compute_gmm_J(int nruns,
  int d, int k, int n, double *alphas,
  double *means, double *icf, double *x,
  Wishart wishart, double& err, double *J)
{
  int icf_sz = d*(d + 1) / 2;
  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  adept::Stack stack;
  adouble *aalphas = new adouble[k];
  adouble *ameans = new adouble[d*k];
  adouble *aicf = new adouble[icf_sz*k];

  high_resolution_clock::time_point start, end;
  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    adept::set_values(aalphas, k, alphas);
    adept::set_values(ameans, d*k, means);
    adept::set_values(aicf, icf_sz*k, icf);

    stack.new_recording();
    adouble aerr;
    gmm_objective(d, k, n, aalphas, ameans,
      aicf, x, wishart, &aerr);
    aerr.set_gradient(1.); // only one J row here
    stack.reverse();

    adept::get_gradients(aalphas, k, J);
    adept::get_gradients(ameans, d*k, &J[k]);
    adept::get_gradients(aicf, icf_sz*k, &J[k + d*k]);
    err = aerr.value();
  }
  end = high_resolution_clock::now();

  delete[] aalphas;
  delete[] ameans;
  delete[] aicf;

  return duration_cast<duration<double>>(end - start).count() / nruns;
}

void test_gmm(const string& fn, int nruns)
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
  for (int i = 0; i < nruns; i++)
  {
    gmm_objective(d, k, n, alphas, means,
      icf, x, wishart, &err);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns;
  cout << "err: " << err << endl;

  tJ = compute_gmm_J(nruns, d, k, n, alphas, means, icf, x, wishart, err, J);
  //tJ = compute_gmm_J_split(nruns, d, k, n, alphas, means, icf, x, wishart, err, J);

  string name = "J_Adept";
  //string name = "J_Adept_split";
  write_J(fn + name + ".txt", Jrows, Jcols, J);
  //write_times(tf, tJ);
  write_times(fn + name + "_times.txt", tf, tJ);

  delete[] J;
  delete[] alphas;
  delete[] means;
  delete[] x;
  delete[] icf;
}

int main(int argc, char *argv[])
{
  string fn(argv[1]);
  int nruns = 1;
  if (argc >= 3)
    nruns = std::stoi(string(argv[2]));
  test_gmm(fn, nruns);
}