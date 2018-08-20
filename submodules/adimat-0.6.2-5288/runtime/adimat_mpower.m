% function [z] = adimat_mpower(a, b)
%
% Compute z = a ^ b. This is a re-implementation of the mpower
% builtin to be differentiated with ADiMat.
%
% see also adimat_expm
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm
%
function z = adimat_mpower(a, b)
  if isscalar(a) && isscalar(b)
    z = a .^ b;
  elseif isscalar(a)
    z = expm(b .* log(a));
  else
    z = expm(b .* logm(a));
  end
end
% $Id: adimat_mpower.m 4571 2014-06-20 18:30:53Z willkomm $
