function err = example_gmm_objective(params, data)
% EXAMPLE_GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%         First argument PARAMS stores GMM
%             params.log_alphas  
%                vector of logs of mixture weights (unnormalized), so
%                weights = exp(log_alphas)/sum(exp(log_alphas))
%             params.means
%                Cell array of component means (each dimension dx1)
%             params.inv_cov_factors 
%                Cell array of d*(d+1)/2 vectors, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
%      To generate params given covariance C:
%           L = chol(C)';
%           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]

%      This will be mexed by au_ccode, so doesn't need to be super fast.
%      Answer is scaled by (2*pi)^d/2

% Derivation of nll
% weight[k] = exp(alphas[k])/sum(exp(alphas))
% Sigma[k] = inv(Ls[k]'*Ls[k])
% mahal2[k] = (mus[k] - x)'*inv(Sigma[k])*(mus[k] - x)
% mahal[k] = Ls[k]*(mus[k] - x)
% log(sum_k weight[k] * det(2*pi*Sigma[k])^-0.5 * exp(-0.5*sumsq(mahal[k])))
% = log(sum_k weight[k] * det(Ls[k]) * exp(-0.5*sumsq(mahal[k])))
% =log(sum_k exp(alphas[k])/sum(exp(alphas)) * exp(log(det(Ls[k])) * exp(-0.5*sumsq(mahal_k)))
% =log(1/sum(exp(alphas)) * sum_k { exp(alphas[k]) * exp(log(det(Ls[k])) * exp(-0.5*sumsq(mahal_k)))
% =log(1/sum(exp(alphas)) * sum_k exp(alphas[k]) + log(det(Ls[k])) - 0.5*sumsq(mahal_k)))
% =-log(sum(exp(alphas)) + 
%       log(sum_k exp(alphas[k] + log(det(Ls[k])) - 0.5*sumsq(mahal_k)))
% =-log(sum(exp(alphas)) + 
%       log(sum_k exp(alphas[k] + log(prod(diag(Ls[k]))) - 0.5*sumsq(mahal_k)))
% =-log(sum(exp(alphas)) + 
%       log(sum_k exp(alphas[k] + log(prod(exp(diag(Ls0[k])))) - 0.5*sumsq(mahal_k)))
% =-log(sum(exp(alphas)) + 
%       log(sum_k exp(alphas[k] + sum(diag(Ls0[k])) - 0.5*sumsq(mahal_k)))



if nargin == 0
    %%
    
    % Make a small random GMM
    d = 2;
    K = 4;
    params.log_alphas = randn(K,1);
    params.means = au_map(@(i) rand(d,1), cell(K,1));
    params.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(K,1));

    % Flatten the parameters into a vector
    x = au_deep_vectorize(params);
    
    % And make an "unflattening" function
    unvec = @(x) au_deep_unvectorize(params, x);
    
    % Make some random data
    data = [
        randn(d,1);
        1.0];
    
    % Test call of the function
    f = @(x,data) example_gmm_objective(unvec(x), data);
    f(x, data)
    
    au_autodiff_generate(f, x, data, 'example_gmm_objective_mex.cxx')
    return
end

d = size(data,1)-1;
K = size(params.log_alphas,1);
log_alphas = params.log_alphas;
means = [params.means{:}];

lower_triangle_indices = tril(ones(d,d), -1) ~= 0;

x = data(1:d);
logsumexp_offset = data(d+1);

lse = zeros(K,1, 'like', log_alphas);
for k=1:K
    % Unpack L parameters into d*d matrix.
    Lparams = params.inv_cov_factors{k};
    % Set L's diagonal
    logLdiag = Lparams(1:d);
    L = diag(exp(logLdiag));
    % And set lower triangle
    L(lower_triangle_indices) = Lparams(d+1:end);

    mahal = L*(means(:,k) - x);
    lse(k) = log_alphas(k) + sum(logLdiag) - 0.5*(mahal'*mahal);
end
err = log(sum(exp(lse-logsumexp_offset)))+logsumexp_offset - au_logsumexp(log_alphas);
