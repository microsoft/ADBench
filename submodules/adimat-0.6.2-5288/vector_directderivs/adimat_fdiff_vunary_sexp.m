% function [d_res res] = adimat_fdiff_vunary_sexp(d_x, x, dpfun)
%
% Compute derivative d_res and function result res of unary vector
% function whos diagonal partial derivative is returned by dpfun(x).
%
% This version of the function can also deal with scalar expansion, as
% it happens for example with besselj(1:3, 0.5) or besselj(0.5, 1:3).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012,2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [d_res res varargout] = adimat_fdiff_vunary_sexp(d_x, x, dpfun)
  sz = size(d_x);
  [ndd nel] = size(d_x);
  [dpartial res varargout{3:nargout}] = dpfun(x);
  if nel == 1 && length(dpartial) > 1
    nel = length(dpartial);
    d_x = repmat(d_x, [1 nel]);
  end
  dpartial = repmat(reshape(dpartial, [1 nel]), [ndd 1]);
  d_res = reshape(d_x(:,:) .* dpartial, [ndd size(res)]);
end
% $Id: adimat_fdiff_vunary_sexp.m 3873 2013-09-22 09:17:57Z willkomm $
