#include <iostream>
#include <string>
#include <chrono>
#include <set>

#define DO_GMM_FULL
//#define DO_GMM_SPLIT

#include "adept.h"
#include "../utils.h"
#include "../defs.h"

#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
#define ADEPT_COMPILATION
#include "../ADOLC/gmm.h"
#endif

using adept::adouble;
using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

#ifdef DO_GMM_FULL

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

#elif defined DO_GMM_SPLIT

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

#endif
#if defined DO_GMM_FULL || defined DO_GMM_SPLIT

void test_gmm(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J, bool replicate_point)
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
  high_resolution_clock::time_point start, end;
  double tf, tJ = 0.;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    gmm_objective(d, k, n, alphas.data(), means.data(),
      icf.data(), x.data(), wishart, &err);
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;
  cout << "err: " << err << endl;

#ifdef DO_GMM_FULL
  string name = "Adept";
  tJ = compute_gmm_J(nruns_J, d, k, n, alphas.data(), means.data(),
    icf.data(), x.data(), wishart, err, J.data());
#elif defined DO_GMM_SPLIT
  string name = "Adept_split";
  tJ = compute_gmm_J_split(nruns_J, d, k, n, alphas.data(), means.data(), 
    icf.data(), x.data(), wishart, err, J.data());
#endif

  write_J(fn_out + "_J_" + name + ".txt", Jrows, Jcols, J.data());
  //write_times(tf, tJ);
  write_times(fn_out + "_times_" + name + ".txt", tf, tJ);
}

#endif

int main(int argc, char *argv[])
{
  string dir_in(argv[1]);
  string dir_out(argv[2]);
  string fn(argv[3]);
  int nruns_f = std::stoi(string(argv[4]));
  int nruns_J = std::stoi(string(argv[5]));

  // read only 1 point and replicate it?
  bool replicate_point = (argc >= 7 && string(argv[6]).compare("-rep") == 0);

#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
  test_gmm(dir_in + fn, dir_out + fn, nruns_f, nruns_J, replicate_point);
#endif
}