% function tobj = tay_zeros(c)
%
% see also a_zeros, adimat_adjoint, tseries3
%
% This file is part of the ADiMat runtime environment
%
function tobj = tay_zeros(c)
  if isobject(c)
    tobj = zerobj(c);
  else
    tobj = tseries2(zeros(size(c)));
  end

% $Id: tay_zeros.m 4589 2014-06-22 08:14:54Z willkomm $
