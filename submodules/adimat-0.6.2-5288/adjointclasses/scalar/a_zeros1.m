% function adj = a_zeros1(v)
%
% Create zero adjoints. This function creates zero derivatives of
% class double, by calling the function zeros. These adjoints are used
% in scalar reverse mode.
%
% see also zeros, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function adj = a_zeros1(c)
  if iscell(c)
    adj = cell(size(c));
    [adj{:}] = a_zeros(c{:});
  elseif isstruct(c)
    adj = a_struct(c);
  else
    adj = zeros(size(c));
  end
     
% $Id: a_zeros1.m 4263 2014-05-20 07:36:37Z willkomm $
