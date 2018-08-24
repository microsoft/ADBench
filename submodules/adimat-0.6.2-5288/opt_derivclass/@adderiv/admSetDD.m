% ADDERIV/admSetDD
% function g_x = admSetDD(g_x, i, dd)
%
% Set i-th directional derivative of g_x to data given by dd.
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function g_x = admSetDD(g_x, i, dd)
  g_x.deriv{i} = reshape(dd, size(g_x.deriv{1}));
% $Id: admSetDD.m 3253 2012-03-27 15:14:31Z willkomm $
