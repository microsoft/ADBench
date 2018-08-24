% function varargout = a_zeros1(v)
%
% Create zero adjoints. This function creates zero derivative objects
% of the current derivative class selected with adimat_derivclass, by
% calling the function g_zeros. These adjoints are used in vector
% reverse mode.
%
% see also g_zeros, adimat_derivclass, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
function adj = a_zeros1(c)
  if iscell(c)
    adj = cell(size(c));
    [adj{:}] = a_zeros(c{:});
  elseif isstruct(c)
    adj = a_struct(c);
  else
    adj = tay_zeros(c);
  end

% $Id: a_zeros1.m 4391 2014-05-30 14:39:26Z willkomm $
