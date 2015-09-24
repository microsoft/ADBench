function err = gmm_objective_adigator(params, x)
% GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%         First argument PARAMS stores GMM
%             params.log_alphas 
%                1 x k vector of logs of mixture weights (unnormalized), so
%                weights = exp(log_alphas)/sum(exp(log_alphas))
%             params.means
%                d x k matrix of component means
%             params.inv_cov_factors 
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
%         Second argument X is a data point (dx1 vector)
%      To generate params given covariance C:
%           L = inv(chol(C,'lower'));
%           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]

%      This will be mexed by au_ccode, so doesn't need to be super fast.


d = size(x,1);
k = size(params.alphas,2);
alphas = params.alphas;
means = params.means;

% lower_triangle_indices = my_tril(ones(d,d), -1) ~= 0;
% 
% lse = zeros(k,1);
% for ik=1:k
%     % Unpack L parameters into d*d matrix.
%     Lparams = params.inv_cov_factors(:,ik);
%     % Set L's diagonal
%     logLdiag = Lparams(1:d);
%     L = diag(exp(logLdiag));
%     % And set lower triangle
%     L(lower_triangle_indices) = Lparams(d+1:end);
% 
%     mahal = L*(means(:,ik) - x);
%     lse(ik) = alphas(ik) + sum(logLdiag) - 0.5*(mahal'*mahal);
% end

constant = 1 / sqrt(2*pi)^d;
err = log(constant);
% err = err + logsumexp(lse);
err = err - logsumexp(alphas);
% err = log(constant) + log(sum(exp(lse))) - log(sum(exp(alphas)));

end