#include <iostream>
#include <string>
#include <chrono>
#include <set>

#define DO_GMM_FULL
//#define DO_GMM_SPLIT
//#define DO_BA

#include "adept.h"
#include "../utils.h"
#include "../defs.h"

#if defined DO_GMM_FULL || defined DO_GMM_SPLIT
#define ADEPT_COMPILATION
#include "../gmm.h"
#elif defined DO_BA
#include "../ba.h"
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

#elif defined DO_BA
double compute_ba_J(int nruns, int n, int m, int p,
  double *cams, double *X, double *w, int *obs, double *feats,
  double *reproj_err, double *w_err, BASparseMat *J)
{
  if (nruns == 0)
    return 0.;

  adept::Stack stack;
  adouble acam[BA_NCAMPARAMS],
    aX[3], aw, areproj_err[2], aw_err;
  int n_new_cols = BA_NCAMPARAMS + 3 + 1;
  vector<double> reproj_err_d(2 * n_new_cols);

  high_resolution_clock::time_point start, end;
  start = high_resolution_clock::now();
  for (int i = 0; i < nruns; i++)
  {
    *J = BASparseMat(n, m, p);

    for (int i = 0; i < p; i++)
    {
      memset(reproj_err_d.data(), 0, 2 * n_new_cols*sizeof(double));

      int camIdx = obs[2 * i + 0];
      int ptIdx = obs[2 * i + 1];
      adept::set_values(acam, BA_NCAMPARAMS, &cams[BA_NCAMPARAMS*camIdx]);
      adept::set_values(aX, 3, &X[ptIdx * 3]);
      aw.set_value(w[i]);

      stack.new_recording();
      computeReprojError(acam, aX, &aw, &feats[2 * i], areproj_err);
      stack.independent(acam, BA_NCAMPARAMS);
      stack.independent(aX, 3);
      stack.independent(aw);
      stack.dependent(areproj_err, 2);
      stack.jacobian_reverse(reproj_err_d.data());

      adept::get_values(areproj_err, 2, &reproj_err[2 * i]);

      J->insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
    }

    for (int i = 0; i < p; i++)
    {
      aw.set_value(w[i]);
      
      stack.new_recording();
      computeZachWeightError(&aw, &aw_err);
      aw_err.set_gradient(1.);
      stack.reverse();

      w_err[i] = aw_err.value();
      double err_d = aw.get_gradient();

      J->insert_w_err_block(i, err_d);
    }
  }

  end = high_resolution_clock::now();
  double t_J = duration_cast<duration<double>>(end - start).count() / nruns;
  cout << "t_J:" << t_J << endl;

  return t_J;
}

void test_ba(const string& fn_in, const string& fn_out,
  int nruns_f, int nruns_J)
{
  int n, m, p;
  vector<double> cams, X, w, feats;
  vector<int> obs;

  read_ba_instance(fn_in + ".txt", n, m, p,
    cams, X, w, obs, feats);

  vector<double> reproj_err(2 * p);
  vector<double> w_err(p);
  BASparseMat J(n, m, p);

  high_resolution_clock::time_point start, end;
  double tf = 0., tJ = 0;

  start = high_resolution_clock::now();
  for (int i = 0; i < nruns_f; i++)
  {
    ba_objective(n, m, p, cams.data(), X.data(),
      w.data(), obs.data(), feats.data(),
      reproj_err.data(), w_err.data());
  }
  end = high_resolution_clock::now();
  tf = duration_cast<duration<double>>(end - start).count() / nruns_f;

  string name("Adept");
  tJ = compute_ba_J(nruns_J, n, m, p, cams.data(), X.data(), w.data(),
    obs.data(), feats.data(), reproj_err.data(), w_err.data(), &J);

  //write_J_sparse(fn_out + "_J_" + name + ".txt", J);
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
#elif defined DO_BA
  test_ba(dir_in + fn, dir_out + fn, nruns_f, nruns_J);
#endif
}