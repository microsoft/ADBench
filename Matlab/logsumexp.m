function out = logsumexp(x)
% LOGSUMEXP  Compute log(sum(exp(x))) stably.
%               X is k x n
%               OUT is 1 x n

mx = max(x);
emx = exp(bsxfun(@minus, x, mx));
semx = sum(emx);
out = log(semx) + mx;