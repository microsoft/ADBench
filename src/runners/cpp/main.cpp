#include <string>


int main(int argc, char* argv[])
{
	if (argc < 6) {
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