% function adj = a_fft(adj, ind, a, n, dim)
%
% Compute adjoint of z = fft(x, n?, dim?).
%
% see also a_fft
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_fft(adj, ind, a, n, dim)
  if nargin < 5
    if isscalar(a)
      dim = 2; 
    else
      dim = adimat_first_nonsingleton(a);
    end
  end
  sza = size(a);
  if nargin < 4
    n = sza(dim);
  end
  if dim > length(sza) || sza(dim) == 1
    % in this case, fft is like repmat(a, [1 1 ... n ... 1 1])
    adj = call(@sum, adj, dim);
  else
    fulln = sza(dim);
    adj = call(@fft, adj, n, dim);
    if fulln > n
      padcnt = zeros(length(sza));
      padcnt(dim) = fulln - n;
      adj = call(@adimat_padarray, adj, padcnt);
    elseif fulln < n
      indices = repmat({':'}, [1 length(sza)]);
      indices{dim} = 1:fulln;
      adj = adj(indices{:});
    end
  end

% $Id: a_fft.m 3670 2013-05-27 08:20:23Z willkomm $
