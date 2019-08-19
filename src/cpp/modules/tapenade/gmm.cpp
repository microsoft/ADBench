#include "gmm.h"

/* ==================================================================== */
/*                                UTILS                                 */
/* ==================================================================== */

// This throws error on n<1
double arr_max(int n, const double* const x)
{
	double m = x[0];
	for (int i = 1; i < n; i++)
	{
		if (m < x[i])
		{
			m = x[i];
	    }
	}

	return m;
}

// sum of component squares
double sqnorm(int n, const double* const x)
{
	double res = x[0] * x[0];
	for (int i = 1; i < n; i++)
	{
		res = res + x[i] * x[i];
	}

	return res;
}

// out = a - b
void subtract(
	int d,
	const double* const x,
	const double* const y,
	double* out
)
{
	for (int id = 0; id < d; id++)
	{
		out[id] = x[id] - y[id];
	}
}

double logsumexp(int n, const double* const x)
{
	double mx = arr_max(n, x);
	double semx = 0.;
	for (int i = 0; i < n; i++)
	{
		semx = semx + exp(x[i] - mx);
	}

	return log(semx) + mx;
}

double log_gamma_distrib(double a, double p)
{
	double out = 0.25 * p * (p - 1) * log(PI);
	int j;

	for (j = 1; j <= p; j++)
	{
		out = out + lgamma(a + 0.5 * (1 - j));
	}

	return out;
}




/* ======================================================================== */
/*                                MAIN LOGIC                                */
/* ======================================================================== */

double log_wishart_prior(
	int p,
	int k,
	Wishart wishart,
	const double* const sum_qs,
	const double* const Qdiags,
	const double* const icf
)
{
	int n = p + wishart.m + 1;
	int icf_sz = p * (p + 1) / 2;

	double C = n * p * (log(wishart.gamma) - 0.5 * log(2)) - log_gamma_distrib(0.5 * n, p);

	double out = 0;
	for (int ik = 0; ik < k; ik++)
	{
		double frobenius = sqnorm(p, &Qdiags[ik * p]) + sqnorm(icf_sz - p, &icf[ik * icf_sz + p]);
		out = out + 0.5 * wishart.gamma * wishart.gamma * (frobenius)
			-wishart.m * sum_qs[ik];
	}

	return out - k * C;
}


void preprocess_qs(
	int d,
	int k,
	const double* const icf,
	double* sum_qs,
	double* Qdiags
)
{
	int icf_sz = d * (d + 1) / 2;
	for (int ik = 0; ik < k; ik++)
	{
		sum_qs[ik] = 0.;
		for (int id = 0; id < d; id++)
		{
			double q = icf[ik * icf_sz + id];
			sum_qs[ik] = sum_qs[ik] + q;
			Qdiags[ik * d + id] = exp(q);
		}
	}
}


void Qtimesx(
	int d,
	const double* const Qdiag,
	const double* const ltri, // strictly lower triangular part
	const double* const x,
	double* out
)
{
	for (int id = 0; id < d; id++)
	{
		out[id] = Qdiag[id] * x[id];
	}

	int Lparamsidx = 0;
	for (int i = 0; i < d; i++)
	{
		for (int j = i + 1; j < d; j++)
		{
			out[j] = out[j] + ltri[Lparamsidx] * x[i];
			Lparamsidx++;
		}
	}
}


void gmm_objective(
	int d,
	int k,
	int n,
	const double* const alphas,
	const double* const means,
	const double* const icf,
	const double* const x,
	Wishart wishart,
	double* err
)
{
	const double CONSTANT = -n * d * 0.5 * log(2 * PI);
	int icf_sz = d * (d + 1) / 2;

	double* Qdiags = (double*)malloc(d * k * sizeof(double));
	double* sum_qs = (double*)malloc(k * sizeof(double));
	double* xcentered = (double*)malloc(d * sizeof(double));
	double* Qxcentered = (double*)malloc(d * sizeof(double));
	double* main_term = (double*)malloc(k * sizeof(double));

	preprocess_qs(d, k, icf, &sum_qs[0], &Qdiags[0]);

	double slse = 0.;
	for (int ix = 0; ix < n; ix++)
	{
		for (int ik = 0; ik < k; ik++)
		{
			subtract(d, &x[ix * d], &means[ik * d], &xcentered[0]);
			Qtimesx(d, &Qdiags[ik * d], &icf[ik * icf_sz + d], &xcentered[0], &Qxcentered[0]);

			main_term[ik] = alphas[ik] + sum_qs[ik] - 0.5 * sqnorm(d, &Qxcentered[0]);
		}
		slse = slse + logsumexp(k, &main_term[0]);
	}

	double lse_alphas = logsumexp(k, alphas);
	*err = CONSTANT + slse - n * lse_alphas + log_wishart_prior(d, k, wishart, &sum_qs[0], &Qdiags[0], icf);

	free(Qdiags);
	free(sum_qs);
	free(xcentered);
	free(Qxcentered);
	free(main_term);
}