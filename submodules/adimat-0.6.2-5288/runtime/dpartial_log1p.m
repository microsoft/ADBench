% function [dpartial y] = partial_log1p(x)
%
% Compute partial derivative diagonal of y = log1p(x).
%
% This returns the diagonal of the partial derivative. The partial
% derivative matrix can be obtained by using diag(partial).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_log1p(x)
  dpartial = 1 ./ (x + 1);
  if nargout > 1
    y = log1p(x);
  end

% $Id: dpartial_log1p.m 3247 2012-03-23 15:08:24Z willkomm $
