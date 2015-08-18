function out = logsumexp_repmat(x)
% LOGSUMEXP  Compute log(sum(exp(x))) stably.
%               X is k x n
%               OUT is 1 x n

mx = max(x);
emx = exp(x - repmat(mx,size(x,1),1));
% emx = exp(bsxfun(@minus, x, mx)); % bsxfun does not work with AdiMat
semx = sum(emx);
out = log(semx) + mx;
