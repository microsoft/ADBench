function err = gmm_unoptimized(alphas,means,sigmas,x)
%GMM_UNOPTIMIZED 
%           alphas   1 x k vector such that weights = exp(alphas)
%           means   d x k
%           sigmas cell array of size k with matrix entries d x d
%           x   d x 1 datapoint

d = size(means,1);
k = size(alphas,2);
lse = zeros(1,k);

normweights = sum(exp(alphas));
weights = exp(alphas) / normweights;
constant = 1 / sqrt(2*pi)^d;
for ik=1:k
    xcentered = x - means(:,ik);
    lse(ik) = weights(ik) * constant * ...
        (1/sqrt(det(sigmas{ik}))) * ...
        exp(-0.5 * xcentered' * inv(sigmas{ik}) * xcentered);
end

err = log(sum(lse));

end

