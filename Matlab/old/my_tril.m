function A = my_tril(A,k)
%   TRIL(A) is the lower triangular part of X.
%   TRIL(A,K) is the elements on and below the K-th diagonal
%   of X .  K = 0 is the main diagonal, K > 0 is above the
%   main diagonal and K < 0 is below the main diagonal.
%
%   See TRIL.

% can be done more efficiently?

if nargin == 1
    k = 0;
end

k = k+1;
for i=1:size(A,1)
    k = k+1;
    A(i,k:end) = 0;
end

end