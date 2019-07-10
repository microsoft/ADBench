#include "gmm_simple_d.h"

#include <cmath>
#include <vector>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"

using std::vector;

#include "../../shared/gmm.h"
#include "gmm_d.h"
#include "../../shared/gmm_eigen_simple.h"

#include "Eigen/Dense"

using Eigen::Map;
using Eigen::VectorXd;
using Eigen::RowVectorXd;
using Eigen::ArrayXd;
using Eigen::MatrixXd;
using Eigen::Lower;

void gmm_objective_no_priors_d(int d, int k, int n,
    Map<const ArrayXd> const& alphas,
    vector<Map<const VectorXd>> const& mus,
    ArrayXd const& sum_qs,
    vector<MatrixXd> const& Qs,
    const double* x,
    Wishart wishart,
    double* err,
    double* J)
{
    int icf_sz = d * (d + 1) / 2;
    Map<RowVectorXd> alphas_d(J, k);
    Map<MatrixXd> means_d(&J[k], d, k);
    Map<MatrixXd> icf_d(&J[k + d * k], icf_sz, k);

    VectorXd xcentered(d), Qxcentered(d);
    ArrayXd main_term(k);
    MatrixXd curr_means_d(d, k);
    MatrixXd curr_logLdiag_d(d, k);
    MatrixXd curr_L_d(icf_sz - d, k);
    double slse = 0.;
    for (int ix = 0; ix < n; ix++)
    {
        Map<const VectorXd> curr_x(&x[ix * d], d);
        for (int ik = 0; ik < k; ik++)
        {
            xcentered = curr_x - mus[ik];
            Qxcentered.noalias() = Qs[ik] * xcentered;
            curr_means_d.col(ik).noalias() = Qs[ik].transpose() * Qxcentered;
            curr_logLdiag_d.col(ik).noalias() =
                (1. - ((Qs[ik].diagonal().cwiseProduct(xcentered)).cwiseProduct(Qxcentered)).array()).matrix();

            int Lparamsidx = 0;
            for (int i = 0; i < d; i++)
            {
                int n_curr_elems = d - i - 1;
                curr_L_d.block(Lparamsidx, ik, n_curr_elems, 1) = -xcentered(i) * Qxcentered.bottomRows(n_curr_elems);
                Lparamsidx += n_curr_elems;
            }

            main_term(ik) = -0.5 * Qxcentered.squaredNorm();
        }
        main_term += alphas + sum_qs;
        slse += logsumexp_d(main_term, main_term);
        alphas_d += main_term.matrix();
        means_d += (curr_means_d.array().rowwise() * main_term.transpose()).matrix();
        icf_d.topRows(d) += (curr_logLdiag_d.array().rowwise() * main_term.transpose()).matrix();
        icf_d.bottomRows(icf_sz - d) += (curr_L_d.array().rowwise() * main_term.transpose()).matrix();
    }

    ArrayXd logsumexp_alphas_d;
    double lse_alphas = logsumexp_d(alphas, logsumexp_alphas_d);
    alphas_d -= (n * logsumexp_alphas_d.matrix());

    const double CONSTANT = -n * d * 0.5 * log(2 * PI);
    *err = CONSTANT + slse - n * lse_alphas;
}

void gmm_objective_d(int d, int k, int n,
    const double* alphas,
    const double* means,
    const double* icf,
    const double* x,
    Wishart wishart,
    double* err,
    double* J)
{
    int icf_sz = d * (d + 1) / 2;
    int Jsz = k + k * d + k * icf_sz;
    std::fill(J, J + Jsz, (double)0);

    // init eigen wrappers first
    vector<Map<const VectorXd>> mus;
    ArrayXd sum_qs;
    vector<MatrixXd> Qs;
    preprocess(d, k, means, icf, mus, sum_qs, Qs);

    Map<const ArrayXd> map_alphas(alphas, k);
    gmm_objective_no_priors_d(d, k, n, map_alphas, mus, sum_qs,
        Qs, x, wishart, err, J);
    *err += log_wishart_prior_d(d, k, wishart, sum_qs, Qs, icf, J);
}
