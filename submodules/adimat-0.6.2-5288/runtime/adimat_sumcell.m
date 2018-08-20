% function res = adimat_sumscell(a, b)
%   This computes the sum of cells a and b.
%
% see also admDiffRev, adimat_adjsum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
function res = adimat_sumcell(a, b)
  res = cell(size(a));
  for i=1:numel(a)
    res{i} = adimat_adjsum(a{i}, b{i});
  end
  
% $Id: adimat_sumcell.m 3111 2011-11-04 16:51:24Z willkomm $
