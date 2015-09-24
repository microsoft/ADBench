% function [dpartial y] = partial_expm1(x)
%
% Compute partial derivative diagonal of y = expm1(x).
%
% This returns the diagonal of the partial derivative. The partial
% derivative matrix can be obtained by using diag(partial).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_expm1(x)
  dpartial = exp(x);
  if nargout > 1
    y = expm1(x);
  end

% $Id: dpartial_expm1.m 3247 2012-03-23 15:08:24Z willkomm $
