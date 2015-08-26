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

double compute_gmm_J_split(int nruns,
  int d, int k, int n, double *alphas,
  double *means, double *icf, double *x,
  Wishart wishart, double& err, double *J)
{
  int icf_sz = d*(d + 1) / 2;
  int Jrows = 1;
  int Jcols = (k*(d + 1)*(d + 2)) / 2;

  double *J_alphas = &J[0];
  double *J_means = &J[k];
  double *J_icf = &J[k + d*k];
  vector<double> Jtmp(Jcols);
  double *Jtmp_alphas = &Jtmp[0];
  double *Jtmp_means = &Jtmp[k];
  double *Jtmp_icf = &Jtmp[k + d*k];

  adept::Stack stack;
  adouble *aalphas = new adouble[k];
  adouble *ameans = new adouble[d*k];
  adouble *aicf = new adouble[icf_sz*k];
  adouble aerr;

  high_resolution_clock::time_point start, end;
  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    adept::set_values(aalphas, k, alphas);
    adept::set_values(ameans, d*k, means);
    adept::set_values(aicf, icf_sz*k, icf);

    stack.new_recording();
    gmm_objective_split_other(d, k, n, aalphas, ameans,
      aicf, wishart, &aerr);
    aerr.set_gradient(1.); // only one J row here
    stack.reverse();
    
    err = aerr.value();
    adept::get_gradients(aalphas, k, J_alphas);
    adept::get_gradients(ameans, d*k, J_means);
    adept::get_gradients(aicf, icf_sz*k, J_icf);

    for (int ix = 0; ix < n; ix++)
    {
      stack.new_recording();
      gmm_objective_split_inner(d, k, aalphas, ameans,
        aicf, &x[ix*d], wishart, &aerr);
      aerr.set_gradient(1.);
      stack.reverse();

      err += aerr.value();
      adept::get_gradients(aalphas, k, Jtmp_alphas);
      adept::get_gradients(ameans, d*k, Jtmp_means);
      adept::get_gradients(aicf, icf_sz*k, Jtmp_icf);
      for (int i = 0; i < Jcols; i++)
      {
        J[i] += Jtmp[i];
      }      
    }
  }
  end = high_resolution_clock::now();

  delete[] aalphas;
  delete[] ameans;
  delete[] aicf;

  return duration_cast<duration<double>>(end - start).count() / nruns;
}

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

  //tJ = compute_gmm_J(nruns_J, d, k, n, alphas, means, icf, x, wishart, err, J);
  //tJ = compute_gmm_J_split(nruns_J, d, k, n, alphas, means, icf, x, wishart, err, J);

  //string name = "J_Adept";
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
  int nruns_f = 1;
  int nruns_J = 1;
  if (argc >= 3)
  {
    nruns_f = std::stoi(string(argv[2]));
    nruns_J = std::stoi(string(argv[3]));
  }
  test_gmm(fn, nruns_f, nruns_J);
}