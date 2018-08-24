% function adj = a_ifft(adj, ind, a, varargin)
%
% Compute adjoint of z = ifft(x, n?, dim?) and also of the forms z =
% ifft(..., method), were method is a string.
%
% see also a_fft
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_ifft(adj, ind, a, varargin)
  if length(varargin) > 0 && ischar(varargin{end})
    method = varargin{end};
    methodArg = {method};
    varargin = varargin(1:end-1);
  else
    method = '';
    methodArg = {};
  end
  nargs = length(varargin) + 3;
  if nargs < 5
    if isscalar(a)
      dim = 2; 
    else
      dim = adimat_first_nonsingleton(a);
    end
  else
    dim = varargin{2};
  end
  sza = size(a);
  if nargs < 4
    n = sza(dim);
  else
    n = varargin{1};
  end
  if dim > length(sza) || sza(dim) == 1
    % in this case, fft is like repmat(a, [1 1 ... n ... 1 1])
    adj = call(@sum, adj, dim) ./ n;
  else
    fulln = sza(dim);
    adj = call(@ifft, adj, n, dim);
    if strcmp(method, 'symmetric')
      % then ifft computes the following:
      % if mod(n, 2) == 0
      %   n2 = n ./ 2 + 1;
      % else
      %   n2 = ceil(n ./ 2);
      % end
      % szx = size(x);
      % indices = repmat({':'}, [1 length(szx)]);
      % indices{dim} = 1:n2;
      % p1 = x(indices{:});
      % if mod(n, 2) == 0
      %   indices{dim} = 2:n2-1;
      % else
      %   indices{dim} = 2:n2;
      % end
      % p2 = flipdim(x(indices{:}), dim);
      % x2 = cat(dim, p1, p2);
      % z = ifft(x2, n, dim);
      if mod(n, 2) == 0
        n2 = n ./ 2 + 1;
      else
        n2 = ceil(n ./ 2);
      end
      indices = repmat({':'}, [1 length(sza)]);
      if mod(n, 2) == 0
        indices{dim} = 2:n2-1;
      else
        indices{dim} = 2:n2;
      end
      indices2 = repmat({':'}, [1 length(sza)]);
      indices2{dim} = n2+1:n;
      adj(indices{:}) = adj(indices{:}) + call(@flipdim, adj(indices2{:}), dim);
      adj(indices2{:}) = a_zeros(0);
    end
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

% $Id: a_ifft.m 3670 2013-05-27 08:20:23Z willkomm $
