#include "gmm.h"

#include <math.h>

#include "../defs.h"

// This throws error on n<1
adouble arr_max(int n, adouble *x)
{
	adouble m = x[0];
	for (int i = 1; i < n; i++)
	{
		m = fmax(m, x[i]);
	}
	return m;
}

adouble logsumexp(int n, adouble *x)
{
	adouble mx = arr_max(n, x);
	adouble semx = 0.;
	for (int i = 0; i < n; i++)
	{
		semx += exp(x[i] - mx);
	}
	return log(semx) + mx;
}

adouble log_wishart_prior(int p, int k, Wishart wishart,
	adouble* icf)
{
	int n = p + wishart.m + 1;
	int icf_sz = p*(p + 1) / 2;

	double C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

	adouble out = 0;
	for (int ik = 0; ik < k; ik++)
	{
		adouble frobenius = 0;
		adouble sum_log_diag = 0;
		for (int i = 0; i < p; i++)
		{
			adouble tmp = icf[icf_sz*ik + i];
			sum_log_diag = sum_log_diag + tmp;
			tmp = exp(tmp);
			frobenius = frobenius + tmp*tmp;
		}
		for (int i = p; i < icf_sz; i++)
		{
			adouble tmp = icf[icf_sz*ik + i];
			frobenius = frobenius + tmp*tmp;
		}
		out = out + 0.5*wishart.gamma*wishart.gamma*(frobenius)
			-wishart.m * sum_log_diag;
	}

	return out - k*C;
}

void gmm_objective(int d, int k, int n, adouble *alphas, adouble *means,
	adouble *icf, double *x, Wishart wishart, adouble *err)
{
	const double CONSTANT = -n*d*0.5*log(2 * PI);
	int icf_sz = d*(d + 1) / 2;

	adouble *Ldiag = new adouble[d];
	adouble *xcentered = new adouble[d];
	adouble *mahal = new adouble[d];
	adouble *lse = new adouble[k];

	adouble slse = 0.;
	for (int ix = 0; ix < n; ix++)
	{
		for (int ik = 0; ik < k; ik++)
		{
			int icf_off = ik*icf_sz;
			adouble sumlog_Ldiag = 0.;
			for (int id = 0; id < d; id++)
			{
				sumlog_Ldiag += icf[icf_off + id];
				Ldiag[id] = exp(icf[icf_off + id]);
			}

			for (int id = 0; id < d; id++)
			{
				xcentered[id] = x[ix*d + id] - means[ik*d + id];
				mahal[id] = Ldiag[id] * xcentered[id];
			}
			int Lparamsidx = d;
			for (int i = 0; i < d; i++)
			{
				for (int j = i + 1; j < d; j++)
				{
					mahal[j] += icf[icf_off + Lparamsidx] * xcentered[i];
					Lparamsidx++;
				}
			}
			adouble sqsum_mahal = 0.;
			for (int id = 0; id < d; id++)
			{
				sqsum_mahal += mahal[id] * mahal[id];
			}

			lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_mahal;
		}
		slse += logsumexp(k, lse);
	}

	delete[] mahal;
	delete[] xcentered;
	delete[] Ldiag;
	delete[] lse;

	adouble lse_alphas = logsumexp(k, alphas);

	*err = CONSTANT + slse - n*lse_alphas;

	*err += log_wishart_prior(d, k, wishart, icf);
}

double arr_max(int n, double *x)
{
	double m = x[0];
	for (int i = 1; i < n; i++)
	{
		m = fmax(m, x[i]);
	}
	return m;
}

double logsumexp(int n, double *x)
{
	double mx = arr_max(n, x);
	double semx = 0.;
	for (int i = 0; i < n; i++)
	{
		semx += exp(x[i] - mx);
	}
	return log(semx) + mx;
}

double log_gamma_distrib(double a, double p)
{
	double out = log(pow(PI, 0.25 * p * (p - 1)));
	for (int j = 1; j <= p; j++)
	{
		out += lgamma(a + 0.5*(1 - j));
	}
	return out;
}

double log_wishart_prior(int p, int k, Wishart wishart,
	double* icf)
{
	int n = p + wishart.m + 1;
	int icf_sz = p*(p + 1) / 2;

	double C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p);

	double out = 0;
	for (int ik = 0; ik < k; ik++)
	{
		double frobenius = 0;
		double sum_log_diag = 0;
		for (int i = 0; i < p; i++)
		{
			double tmp = icf[icf_sz*ik + i];
			sum_log_diag = sum_log_diag + tmp;
			tmp = exp(tmp);
			frobenius = frobenius + tmp*tmp;
		}
		for (int i = p; i < icf_sz; i++)
		{
			double tmp = icf[icf_sz*ik + i];
			frobenius = frobenius + tmp*tmp;
		}
		out = out + 0.5*wishart.gamma*wishart.gamma*(frobenius)
			-wishart.m * sum_log_diag;
	}

	return out - k*C;
}

void gmm_objective(int d, int k, int n, double *alphas, double *means,
	double *icf, double *x, Wishart wishart, double *err)
{
	const double CONSTANT = -n*d*0.5*log(2*PI);
	int icf_sz = d*(d + 1) / 2;

	double *Ldiag = new double[d];
	double *xcentered = new double[d];
	double *mahal = new double[d];
	double *lse = new double[k];

	double slse = 0.;
	for (int ix = 0; ix < n; ix++)
	{
		for (int ik = 0; ik < k; ik++)
		{
			int icf_off = ik*icf_sz;
			double sumlog_Ldiag = 0.;
			for (int id = 0; id < d; id++)
			{
				sumlog_Ldiag += icf[icf_off + id];
				Ldiag[id] = exp(icf[icf_off + id]);
			}

			for (int id = 0; id < d; id++)
			{
				xcentered[id] = x[ix*d + id] - means[ik*d + id];
				mahal[id] = Ldiag[id] * xcentered[id];
			}
			int Lparamsidx = d;
			for (int i = 0; i < d; i++)
			{
				for (int j = i + 1; j < d; j++)
				{
					mahal[j] += icf[icf_off + Lparamsidx] * xcentered[i];
					Lparamsidx++;
				}
			}
			double sqsum_mahal = 0.;
			for (int id = 0; id < d; id++)
			{
				sqsum_mahal += mahal[id] * mahal[id];
			}

			lse[ik] = alphas[ik] + sumlog_Ldiag - 0.5*sqsum_mahal;
		}
		slse += logsumexp(k, lse);
	}

	delete[] mahal;
	delete[] xcentered;
	delete[] Ldiag;
	delete[] lse;

	double lse_alphas = logsumexp(k, alphas);

	*err = CONSTANT + slse - n*lse_alphas;

	*err += log_wishart_prior(d, k, wishart, icf);
}
