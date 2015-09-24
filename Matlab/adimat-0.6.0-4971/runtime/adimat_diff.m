% function [r] = adimat_diff2(x, n, dim)
%  
% ADiMat replacement function for diff
%
% see also diff
%
% Copyright (C) 2014,2015 Johannes Willkomm <johannes@johannes.willkomm.de>
function [z] = adimat_diff(x, n, dim)

  if nargin < 2
    n = 1;
  end
  if nargin < 3
    dim = adimat_first_nonsingleton(x);
  end
  
  assert(n == 1);
  
  sz = size(x);
  sz2 = sz;
  sz2(dim) = sz2(dim) - 1;
  
  ind = repmat({':'}, [length(sz), 1]);
  ind2 = ind;

  z = zeros(sz2) .* x(1);

  len = sz(dim);  
  ind{dim} = 1:len-1;
  ind2{dim} = 2:len;
    
  z(ind{:}) = x(ind2{:}) - x(ind{:});

end

% $Id: adimat_diff.m 4956 2015-03-02 14:57:25Z willkomm $
