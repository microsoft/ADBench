% function adj = a_sort(adj, adjind, val, dimind?, mode?)
%
% Compute adjoint of val in z = sort(val, dimind?, mode?) where adj is
% the adjoint of val.
%
% see also a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_sort(adj, adjind, val, dimind, mode)
  if nargin < 4
    dimind = adimat_first_nonsingleton(val);
  end
  if nargin < 5
    mode = 'ascend';
  end
  
  [~, perm] = sort(val, dimind, mode);
  
  adj(perm) = adj;
% $Id: a_sort.m 3798 2013-06-27 09:26:33Z willkomm $
