% function [g_x] = admSetDD(g_x, i, dd)
%
% Set the i-th directional derivative of g_x to data given by
% dd. Index i must always be 1.
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_x] = admSetDD(g_x, i, dd)
  if i ~= 1
    error('i must be 1');
  end
  
  g_x(:) = dd(:);
% $Id: admSetDD.m 3253 2012-03-27 15:14:31Z willkomm $
