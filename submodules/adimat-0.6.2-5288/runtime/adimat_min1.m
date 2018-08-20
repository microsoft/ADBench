%
% function r = adimat_min1(val, adj)
%   this determines the adjoint value of min(val), 
%   where the adjoint of val is given as parameter adj
%
% see also adimat_allsum, adimat_adjmultl, adimat_adjmultr
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_min1(val, adj)
  [mv, mi] = min(val);
  adjVect = a_zeros(val);
  if numel(mi) == 1
    adjVect(mi) = adj;
  else
    for i=1:numel(mi)
      adjVect(mi(i), i) = adj(i);
    end
  end
  r = adjVect;
% $Id: adimat_min1.m 1811 2010-04-02 14:36:36Z willkomm $
