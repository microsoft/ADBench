% function adj = a_sort(adj, adjind, val, dim?, mode?)
%
% Compute adjoint of val in z = sort(val, dim?, mode?) where adj is
% the adjoint of val.
%
% see also a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2013,2015 Johannes Willkomm
function adj = a_sort(adj, adjind, val, dim, mode)
  if nargin < 5
    mode = 'ascend';
  end
  if nargin < 4
    dim = adimat_first_nonsingleton(val);
  elseif ischar(dim)
    mode = dim;
    dim = adimat_first_nonsingleton(val);
  end
  
  if dim <= ndims(val)
    [~, perm] = sort(val, dim, mode);
  
    gP = mk1dperm(perm, dim);
    adj(gP) = adj;
  end
% $Id: a_sort.m 5034 2015-05-20 20:03:39Z willkomm $
