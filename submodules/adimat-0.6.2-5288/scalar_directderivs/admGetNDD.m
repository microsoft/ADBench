% function num = admGetNDD(g_x)
%
% Return the number of directional derivatives of g_x. This function
% returns always 1.
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function num = admGetNDD(g_x)
  num = 1;
% $Id: admGetNDD.m 3254 2012-03-28 09:14:36Z willkomm $
