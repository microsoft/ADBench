class IGMMTester {
	public :

		// This function must be called before any other function.
		virtual void prepare(
			int d, int k, int n,
			vector<double> alphas, vector<double>means,
			vector<double> icf, vector<double> x,
			Wishart wishart,
			int nruns_f, int nruns_J,
			double time_limit) = 0;
		// perform AD
		virtual void performAD(int times) = 0;
		virtual void output() = 0; 
		~IGMMTester();
};