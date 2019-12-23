% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function err = gmm_objective(alphas,means,inv_cov_factors,x,hparams)
% GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%             ALPHAS 
%                1 x k vector of logs of mixture weights (unnormalized), so
%                weights = exp(log_alphas)/sum(exp(log_alphas))
%             MEANS
%                d x k matrix of component means
%             INV_COV_FACTORS 
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
%             X 
%               are data points (d x n vector)
%             HPARAMS
%                [gamma, m] wishart distribution parameters
%         Output ERR is the sum of errors over all points
%      To generate params given covariance C:
%           L = inv(chol(C,'lower'));
%           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]

d = size(x,1);
k = size(alphas,2);
n = size(x,2);

lower_triangle_indices = tril(ones(d,d), -1) ~= 0;

sum_qs = sum(inv_cov_factors(1:d,:),1);
Qs = cell(1,k);
Qdiags = zeros(d,k);
for ik=1:k
    % Unpack parameters into d*d matrix.
    icf = inv_cov_factors(:,ik);
    % Set L's diagonal
    logLdiag = icf(1:d);
    Qdiags(:,ik) = exp(logLdiag);
    Qs{ik} = diag(Qdiags(:,ik));
    % And set lower triangle
    Qs{ik}(lower_triangle_indices) = icf(d+1:end);
end

slse = 0;
for ix=1:n
    main_term = zeros(1,k);
    for ik=1:k
        Qxcentered = Qs{ik}*(x(:,ix) - means(:,ik));
        main_term(ik) = -0.5*sqnorm(Qxcentered);
    end
    main_term = main_term + alphas + sum_qs;
    slse = slse + logsumexp(main_term);
end

constant = -n*d*0.5*log(2*pi);
err = constant + slse - n*logsumexp(alphas);

% apply the prior on covariance
err = err + log_wishart_prior(hparams,d,sum_qs,Qdiags,inv_cov_factors);
end

function out = sqnorm(x)
out = sum(x.^2,1);
end

function out = log_wishart_prior(hparams,p,sum_qs,Qdiags,inv_cov_factors)
% LOG_WISHART_PRIOR  
%               HPARAMS = [gamma m]
%               P data dimension
%             INV_COV_FACTORS
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params

gamma = hparams(1);
m = hparams(2);
n = p+m+1;

term1 = 0.5*gamma^2*(sqnorm(Qdiags) + ...
    sqnorm(inv_cov_factors((p+1):end,:)));
term2 = m*sum_qs;
C = n*p*(log(gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n,p);

out = sum(term1 - term2 - C);
end

function out = log_gamma_distrib(a,p)
out = (0.25*p*(p-1))*log(pi);
for j=1:p
    out = out + gammaln(a + 0.5*(1-j));
end
end

