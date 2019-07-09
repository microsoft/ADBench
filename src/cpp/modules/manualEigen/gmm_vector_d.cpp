#include "gmm_vector_d.h"

#include <cmath>
#include <vector>

#include "../../shared/defs.h"
#include "../../shared/matrix.h"

using std::vector;

#include "../../shared/gmm.h"
#include "gmm_d.h"
#include "../../shared/gmm_eigen_vector.h"

using Eigen::Map;
using Eigen::VectorXd;
using Eigen::RowVectorXd;
using Eigen::ArrayXd;
using Eigen::MatrixXd;
using Eigen::Lower;

// logsumexp of cols
void logsumexp_d(const MatrixXd& X, ArrayXd& lse, MatrixXd& logsumexp_partial_d)
{
    vector<MatrixXd::Index> max_elem_idxs(X.cols());
    RowVectorXd mX(X.cols());
    for (int i = 0; i < X.cols(); i++)
    {
        mX(i) = X.col(i).maxCoeff(&max_elem_idxs[i]);
    }
    logsumexp_partial_d = (X.rowwise() - mX).array().exp().matrix();
    RowVectorXd semX = logsumexp_partial_d.colwise().sum();
    for (int i = 0; i < semX.cols(); i++)
    {
        if (semX(i) == 0.)
        {
            logsumexp_partial_d.col(i).setZero();
        }
        else
        {
            (logsumexp_partial_d.col(i))(max_elem_idxs[i]) -= semX(i);
            logsumexp_partial_d.col(i).array() /= semX(i);
        }
        (logsumexp_partial_d.col(i))(max_elem_idxs[i]) += 1.;
    }
    lse = semX.array().log() + mX.array();
}

void gmm_objective_no_priors_d(int d, int k, int n,
    Map<const ArrayXd> const& alphas,
    Map<const MatrixXd> const& means,
    ArrayXd const& sum_qs,
    vector<MatrixXd> const& Qs,
    Map<const MatrixXd> const& x,
    Wishart wishart,
    double* err,
    double* J)
{
    int icf_sz = d * (d + 1) / 2;
    Map<RowVectorXd> alphas_d(J, k);
    Map<MatrixXd> means_d(&J[k], d, k);
    Map<MatrixXd> icf_d(&J[k + d * k], icf_sz, k);

    MatrixXd xcentered(d, n);
    MatrixXd Qxcentered(d, n);
    MatrixXd main_term(k, n);
    vector<MatrixXd> tmp_means_d(k);
    vector<MatrixXd> tmp_qs_d(k);
    vector<MatrixXd> tmp_L_d(k);
    for (int ik = 0; ik < k; ik++)
    {
        xcentered = x.colwise() - means.col(ik);
        Qxcentered.noalias() = Qs[ik] * xcentered;
        main_term.row(ik) = -0.5 * Qxcentered.colwise().squaredNorm();

        tmp_means_d[ik].noalias() = Qs[ik].transpose() * Qxcentered;
        tmp_qs_d[ik].noalias() = (1. -
            (xcentered.cwiseProduct(Qxcentered).array().colwise() * Qs[ik].diagonal().array()))
            .matrix();


        tmp_L_d[ik].resize(icf_sz - d, n);
        int Lparamsidx = 0;
        for (int i = 0; i < d; i++)
        {
            int n_curr_elems = d - i - 1;
            tmp_L_d[ik].middleRows(Lparamsidx, n_curr_elems).noalias() =
                -(Qxcentered.bottomRows(n_curr_elems).array().rowwise() * xcentered.row(i).array()).matrix();
            Lparamsidx += n_curr_elems;
        }
    }
    main_term.colwise() += (alphas + sum_qs).matrix();
    ArrayXd slse;
    logsumexp_d(main_term, slse, main_term);

    alphas_d = main_term.rowwise().sum().transpose();

    for (int ik = 0; ik < k; ik++)
    {
        means_d.col(ik) = (tmp_means_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
        icf_d.col(ik).topRows(d) = (tmp_qs_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
        icf_d.col(ik).bottomRows(icf_sz - d) = (tmp_L_d[ik].array().rowwise() * main_term.row(ik).array()).rowwise().sum();
    }

    ArrayXd logsumexp_alphas_d;
    double lse_alphas = logsumexp_d(alphas, logsumexp_alphas_d);
    alphas_d -= (n * logsumexp_alphas_d.matrix());

    double CONSTANT = -n * d * 0.5 * log(2 * PI);
    double tmp = slse.sum();
    *err = CONSTANT + slse.sum() - n * lse_alphas;
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
    Map<const ArrayXd> map_alphas(alphas, k);
    Map<const MatrixXd> map_means(means, d, k);
    Map<const MatrixXd> map_x(x, d, n);

    ArrayXd sum_qs;
    vector<MatrixXd> Qs;
    preprocess(d, k, icf, sum_qs, Qs);

    gmm_objective_no_priors_d(d, k, n, map_alphas, map_means, sum_qs,
        Qs, map_x, wishart, err, J);
    *err += log_wishart_prior_d(d, k, wishart, sum_qs, Qs, icf, J);
}
