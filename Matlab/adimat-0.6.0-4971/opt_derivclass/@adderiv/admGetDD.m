% ADDERIV/admGetDD
% function dd = admGetDD(g_x, i)
%
% Return the i-th directional derivative of g_x.
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function varargout = admGetDD(g_x, i)
  varargout = cell(1, numel(g_x, i));
  [varargout{:}] = deal(g_x.deriv{i});
% $Id: admGetDD.m 3254 2012-03-28 09:14:36Z willkomm $
