% function [g_z z] = adimat_g_mldivide2(a, g_b, b)
%
% Compute derivative of z = a \ b, matrix left division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_mldivide2(a, g_b, b)

  [m n] = size(a);
  
  z = a \ b;
  if isscalar(a)
    g_z = g_b ./ a;
  else
    g_z = a \ g_b;
  end

% $Id: adimat_g_mldivide2.m 4817 2014-10-09 11:54:22Z willkomm $
