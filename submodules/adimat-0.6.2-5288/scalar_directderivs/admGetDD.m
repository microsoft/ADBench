% function dd = admGetDD(g_x, i)
%
% Return the i-th directional derivative of g_x. Index i must always
% be 1.
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function dd = admGetDD(g_x, i)
  if i ~= 1
    error('i must be 1');
  end
  
  dd = g_x;
% $Id: admGetDD.m 3253 2012-03-27 15:14:31Z willkomm $
