% function adj = a_ifft2(adj, ind, a, m?, n?)
%
% Compute adjoint of z = ifft2(x, m?, n?).
%
% see also a_fft
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_ifft2(adj, ind, a, m, n)
  sza = size(a);
  if nargin < 5
    n = sza(2);
  end
  if nargin < 4
    m = sza(1);
  end
  szf = [m n];
  
  for dim=[2 1]
    adj = a_ifft(adj, ind, a, szf(dim), dim);
  end

% $Id: a_ifft2.m 3672 2013-05-27 10:32:35Z willkomm $
