% function r = adimat_opdiff_sol(t_val1, val1, t_val2, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_sol(t_val1, val1, t_val2, val2)
  if isscalar(val1)
    [t_res res] = adimat_opdiff_ediv(t_val2, val2, t_val1, val1);
  else
    error('adimat:taylor:notimplemented', 'matrix division not implemented');
  end
% $Id: adimat_opdiff_sol.m 3563 2013-04-11 09:27:04Z willkomm $
