% function adj = a_fftn(adj, ind, a, sz)
%
% Compute adjoint of z = fftn(x, sz?).
%
% see also a_fft
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_fftn(adj, ind, a, szf)
  if nargin < 4
    szf = size(a);
  end

  for dim=fliplr(1:length(szf))
    adj = a_fft(adj, ind, a, szf(dim), dim);
  end

% $Id: a_fftn.m 3672 2013-05-27 10:32:35Z willkomm $
