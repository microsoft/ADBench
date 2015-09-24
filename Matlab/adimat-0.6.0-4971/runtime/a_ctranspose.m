% function adj = a_ctranspose(adj, val)
%
% compute adjoint of val in z = ctranspose(val), where adj is the
% adjoint of z.
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm
%
function adj = a_ctranspose(adj, val)
  
%   nz = val ~= 0;
%   factor = ones(size(val));
  
% %  x = val
% %  ax = conj(val)
  
% %  ax = angle(val(nz)) ./ pi .* 180
% %  acx = angle(conj(val(nz))) ./ pi .* 180
  
%   factor(nz) = conj(val(nz)) ./ val(nz);
  
% %  afactor = angle(factor) ./ pi .* 180

%   assert(sum(abs(factor(:))) ./ numel(val) - 1 < 1e-10);
  
%   adj = adj.' .* factor;

  adj = adj';

% $Id: a_ctranspose.m 3898 2013-10-08 09:23:12Z willkomm $
