%
% function r = adimat_max1(val, adj)
%   this determines the adjoint value of max(val), 
%   where the adjoint of val is given as parameter adj
%
% see also adimat_allsum, adimat_adjmultl, adimat_adjmultr
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_max1(val, adj)
  [mv, mi] = max(val);
  adjVect = a_zeros(val);
%  assert(isequal(size(adjVect), size(val)), 'size of adjVect');
%  assert(isequal(size(adj), size(mv)), 'size of adjoint');
%  assert(isequal(numel(find(mi)), numel(adj)), 'size of index');
  if numel(mi) == 1
    adjVect(mi) = adj;
%    assert(isequal(size(adjVect), size(val)), 'case1: size of adjVect');
  else
    for i=1:numel(mi)
      adjVect(mi(i), i) = adj(i);
    end
%    assert(isequal(size(adjVect), size(val)), 'case2: size of adjVect');
  end
  r = adjVect;
%  assert(isequal(size(r), size(val)), 'size of result');
% $Id: adimat_max1.m 1941 2010-05-06 13:05:54Z willkomm $
