// This file was created by taking Manual/main.cpp and hacking it
// about until it supported the Coconut GMM example

#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <cassert>

#include "knossos.h"

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
using ks::vec;

namespace ks {

  double gmm_knossos_gmm_objective(vec<vec<double>> s$x, vec<double> s$alphas,
                                   vec<vec<double>> s$means,
                                   vec<vec<double>> s$qs, vec<vec<double>> s$ls,
                                   double s$wishart_gamma, double s$wishart_m);
}

// Partition into n vectors
template<typename T> vector<vector<T>> partition_into(vector<T> v, int num_groups) {
  assert((v.size() % num_groups) == 0);

  int group_size = v.size() / num_groups;
  vector<vector<T>> groups;

  for (int groupi = 0; groupi < num_groups; groupi++) {
    vector<T> group;

    for (int g = 0; g < group_size; g++) {
      int v_index = groupi * group_size + g;
      group.push_back(v[v_index]);
    }

    groups.push_back(group);
  }

  return groups;
}

template<typename T> vec<T> vector_to_vec(vector<T> vector) {
  vec<T> vec;

  vec.size = vector.size();
  vec.data = new T[vec.size];

  for (int i = 0; i < vec.size; i++) {
    vec.data[i] = vector[i];
  }

  //  cout << vec.size << endl;

  return vec;
}

template<typename T> vec<vec<T>> vector_vector_to_vec_vec(vector<vector<T>> vector_vector) {
  vector<vec<T>> vector_vec;

  for (auto vector : vector_vector) {
    vector_vec.push_back(vector_to_vec(vector));
    //cout << "Should be same (construction)" << endl;
    //cout << vector.size() << endl;
    //cout << vector_vec.back().size << endl;
    //cout << "---" << endl;
  }

  //cout << "Calling vector_to_vec" << endl;

  auto ret = vector_to_vec(vector_vec);

  //cout << "Should be same (after)" << endl;
  //cout << ret.data[0].size << endl; 
  //cout << vector_vec[0].size << endl; 
  //cout << "---" << endl;

  return ret;
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

  // Knossos GMM code expects the qs to be not exped
  for (double &q: Qdiags) q = log(q);

  auto alphasv =  vector_to_vec(alphas);
  auto xv = vector_vector_to_vec_vec(partition_into(x, n));
  auto meansv = vector_vector_to_vec_vec(partition_into(means, k));
  auto Qdiagsv = vector_vector_to_vec_vec(partition_into(Qdiags, k));
  auto lsv = vector_vector_to_vec_vec(partition_into(ls, k));

  //cout << "alphasv: " << alphasv.size << endl;
  //cout << "xv: " << xv.size << endl;
  //cout << "xv: " << xv.data[1].size << endl;
  //cout << "meansv: " << meansv.size << endl;
  //cout << "meansv: " << meansv.data[1].size << endl;
  //cout << "Qdiagsv: " << Qdiagsv.size << endl;
  //cout << "Qdiagsv: " << Qdiagsv.data[1].size << endl;
  //cout << "lsv: " << lsv.size << endl;
  //cout << "lsv: " << lsv.data[1].size << endl;

  // Test
  double tf = timer(
      nruns_f,
      time_limit,
      [&]() {
        err = ks::gmm_knossos_gmm_objective(xv,
                                            alphasv,
                                            meansv,
                                            Qdiagsv,
                                            lsv,
                                            wishart.gamma,
                                            wishart.m);
        ks::g_alloc.reset();
      });
  cout << "err: " << err << endl;

  string name("knossos");
  // We're not doing the Jacobian yet
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
