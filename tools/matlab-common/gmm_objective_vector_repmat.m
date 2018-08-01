function err = gmm_objective_vector_repmat(alphas,means,inv_cov_factors,x,hparams)
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

lse = zeros(k,n,'like',alphas);
for ik=1:k
    % Unpack L parameters into d*d matrix.
    Lparams = inv_cov_factors(:,ik);
    % Set L's diagonal
    logLdiag = Lparams(1:d);
    Q = diag(exp(logLdiag));
    % And set lower triangle
    Q(lower_triangle_indices) = Lparams(d+1:end);
    
    mahal = Q*(x - repmat(means(:,ik),1,n));
%     mahal = L*bsxfun(@minus,means(:,ik),x); % bsxfun does not work with AdiMat
    
    lse(ik,:) = alphas(ik) + sum(logLdiag) - 0.5 * sum(mahal.^2,1);
end

constant = -n*d*0.5*log(2*pi);
err = constant + sum(logsumexp_repmat(lse)) - n*logsumexp_repmat(alphas);

% apply the prior on covariance
err = err + log_wishart_prior(hparams,d,inv_cov_factors);

end

function out = log_wishart_prior(hparams,p,inv_cov_factors)
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

term1 = 0.5*gamma^2*(sum(exp(inv_cov_factors(1:p,:)).^2,1) + ...
    sum(inv_cov_factors((p+1):end,:).^2,1));
term2 = m*sum(inv_cov_factors(1:p,:),1);
C = n*p*(log(gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n,p);

out = sum(term1 - term2 - C);

end

function out = log_gamma_distrib(a,p)
out = log(pi^(0.25*p*(p-1)));
for j=1:p
    out = out + gammaln(a + 0.5*(1-j));
end
end
