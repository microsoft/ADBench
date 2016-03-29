function [l, Jacobian] = au_logsumexp(M)
% AU_LOGSUMEXP  Compute log(sum(exp(M))) stably
%                   au_logsumexp(M) = log(sum(exp(M))) 
%                 but avoids under/overflow.
%               [L, Jacobian] = au_logsumexp(M) returns the Jacobian
%               Notice that although sum operates along columns,
%               L is returned as a column vector so that the Jacobian 
%               makes sense.

% awf, may13

if nargin == 0
  %% test
  Ms = {
    -rand(7,1)
    -rand(7,3)
    -rand(1,7)
    [0 0 0 -5 -10 -15 -20 -10 -5]-1000
    [0 0 0 -5 -10 -15 -20 -10 -5]+900
    };
  for k = 1:length(Ms)
    M = Ms{k};
    fprintf('test %d size', k); fprintf(' %d', size(M)); fprintf('\n');
    lseM = log(sum(exp(M)));
    [au_lseM, J] = au_logsumexp(M);
    q = @(x) squeeze(x);
    %au_prmat(q(lseM), q(au_lseM));
    au_check_derivatives(@(x) au_logsumexp(reshape(x, size(M)))', M(:), J);
  end
  
  return
end

if isa(M,'sym')
    l = log(sum(exp(M)));
    return
end

%% Main body
sz = size(M);
if prod(sz) == max(sz)
  A = max(M);
  ema = exp(M-A);
  sema = sum(ema);
  l = log(sema) + A;
  if nargout > 1
      Jacobian = ema(:)'./sema;
  end
else
  A = max(M);
  ema = exp(bsxfun(@minus, M, A));
  sema = sum(ema);
  l = bsxfun(@plus, log(sema), A)';
  if nargout > 1
      [r,c] = size(M);
      JacobEntries = bsxfun(@rdivide, ema, sema);
      Jacobian = sparse(...
          repmat(1:c, r, 1), ...
          reshape(1:r*c, r, c), ...
          JacobEntries);
  end
end
