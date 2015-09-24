% function [dpartial y] = partial_log10(x)
%
% Compute partial derivative diagonal of y = log10(x).
%
% This returns the diagonal of the partial derivative. The partial
% derivative matrix can be obtained by using diag(partial).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_log10(x)
  dpartial = 1 ./ (log(10) .* x);
  if nargout > 1
    y = log10(x);
  end

% $Id: dpartial_log10.m 3247 2012-03-23 15:08:24Z willkomm $
