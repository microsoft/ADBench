function mog = mog_from_params(params, d, K)
npg = d + d*(d+1)/2; % Number of parameters for each Gaussian
np = K*npg + K; % Total number of parameters (including weights)
au_assert_equal('np','size(params(:),1)');
a = params(1:K);
a = exp(a)/sum(exp(a));
idx = find(tril(ones(d,d)));
L = zeros(d,d);
for k=1:K
  mog(k).weight = a(k);
  paramsk = params(K + (k-1)*npg + [1:npg]);
  mog(k).mean = paramsk(d*(d+1)/2+[1:d]);
  L(idx) = paramsk([1:d*(d+1)/2]);
  mog(k).covariance = inv(L * L');
end
