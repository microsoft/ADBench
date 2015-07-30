#include <iostream>
#include <string>
#include <fstream>
#include <chrono>

#include "../utils.h"
#include "../defs.h"
#include "gmm.h"

using std::cout;
using std::endl;
using std::string;
using namespace std::chrono;

void test_gmm(char *argv[])
{
	int d, k, n;
	double *alphas, *means, *icf, *x;
	double err;
	Wishart wishart;

	// Read instance
	string fn(argv[1]);
	read_gmm_instance(fn + ".txt", d, k, n,
		alphas, means, icf, x, wishart);

	int icf_sz = d*(d + 1) / 2;
	int Jrows = 1;
	int Jcols = (k*(d + 1)*(d + 2)) / 2;

	double *J = new double[Jcols];

	// Test
	high_resolution_clock::time_point start, end;
	double tf, tJ;
	int nruns = 1000;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		gmm_objective(d, k, n, alphas, means,
			icf, x, wishart, &err);
	}
	end = high_resolution_clock::now();
	tf = duration_cast<duration<double>>(end - start).count() / nruns;

	start = high_resolution_clock::now();
	for (int i = 0; i < nruns; i++)
	{
		gmm_objective_d(d, k, n, alphas, means,
			icf, x, wishart, &err, J);
	}
	end = high_resolution_clock::now();
	tJ = duration_cast<duration<double>>(end - start).count() / nruns;

	write_J(fn + "J_manual.txt", Jrows, Jcols, J);
	write_times(tf, tJ);

	delete[] J;
	delete[] alphas;
	delete[] means;
	delete[] x;
	delete[] icf;
}

int main(int argc, char *argv[])
{
	test_gmm(argv);
	//test_ba(argv);
}