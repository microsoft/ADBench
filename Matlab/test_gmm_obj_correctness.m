addpath('awful\matlab')
rng(1)

d = 2;
k = 4;
alphas = randn(k,1);
params.alphas = alphas;
means = au_map(@(i) rand(d,1), cell(k,1));
means = [means{:}];
params.means = means;
sigmas = au_map(@(i) randn(d,d), cell(k,1));
for i=1:k
    sigmas{i} = sigmas{i}*sigmas{i}';
end
params.inv_cov_factors = zeros((d*(d+1)/2),k);
for i=1:k
    L = chol(inv(sigmas{i}),'lower');
    params.inv_cov_factors(:,i) = [log(diag(L)); L(au_tril_indices(d,-1))];
end
x = rand(d,1);

gmm_unoptimized(alphas,means,sigmas,x) - gmm_objective_adigator(params, x)