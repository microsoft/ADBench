function err = gmm_objective(params, x)
% GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%         First argument PARAMS stores GMM
%             params.alphas 
%                1 x k vector of logs of mixture weights (unnormalized), so
%                weights = exp(log_alphas)/sum(exp(log_alphas))
%             params.means
%                d x k matrix of component means
%             params.inv_cov_factors 
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
%         Second argument X are data points (d x n vector)
%         Output ERR is the sum of errors over all points
%      To generate params given covariance C:
%           L = inv(chol(C,'lower'));
%           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]

d = size(x,1);
k = size(params.alphas,2);
n = size(x,2);
alphas = params.alphas;
means = params.means;

lower_triangle_indices = tril(ones(d,d), -1) ~= 0;

lse = zeros(k,n,'like',alphas);
for ik=1:k
    % Unpack L parameters into d*d matrix.
    Lparams = params.inv_cov_factors(:,ik);
    % Set L's diagonal
    logLdiag = Lparams(1:d);
    L = diag(exp(logLdiag));
    % And set lower triangle
    L(lower_triangle_indices) = Lparams(d+1:end);
    
    mahal = L*bsxfun(@minus,means(:,ik),x);
    lse(ik,:) = alphas(ik) + sum(logLdiag) - 0.5 * sum(mahal.^2,1);
end

constant = 1 / sqrt(2*pi)^d;
err = n*log(constant) + sum(logsumexp(lse)) - n*logsumexp(alphas);

end