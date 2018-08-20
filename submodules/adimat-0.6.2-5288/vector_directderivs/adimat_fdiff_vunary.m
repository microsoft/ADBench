% function [d_res res] = adimat_fdiff_vunary(d_x, x, dpfun)
%
% Compute derivative d_res and function result res of unary vector
% function whos diagonal partial derivative is returned by dpfun(x).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [d_res res] = adimat_fdiff_vunary(d_x, x, dpfun)
  if nargout > 1
    [dpartial res] = dpfun(x);
  else
    [dpartial] = dpfun(x);
  end
  d_res = bsxfun(@times, d_x, reshape(dpartial, [1 size(x)]));
end
% $Id: adimat_fdiff_vunary.m 4355 2014-05-28 11:10:28Z willkomm $
