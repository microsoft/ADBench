% function r = a_zeros_index(adjArrayVar, arrayVar, index1, ...)
%   Zero adjoint of index expression after assignment. If the forward
%   assignment changed the size of the array variable, then maybe
%   resize the adjoint here, undoing the size change.  If the size did
%   not change then fill the indexed adjoint with a_zeros.
%
% see also a_zeros, adimat_push_index, adimat_pop_index
%
% This file is part of the ADiMat runtime environment
%
function adj = a_zeros_index(adj, arrayVar, varargin)
  szAdj = size(adj);
  szVar = size(arrayVar);
  if isequal(szAdj, szVar)
    adj(varargin{:}) = a_zeros(arrayVar(varargin{:}));
  else
    test2 = zeros(szVar);
    test2(varargin{:}) = 1;
    test3 = ones(szVar);
    topIndex = num2cell(szAdj);
    test3(topIndex{:}) = 0;
    selwrit = test2 == 1;
    selold = test3 == 1;
    adj(selwrit) = a_zeros(adj(selwrit));
    adj = reshape(adj(selold), szVar);
  end
% $Id: a_zeros_index.m 3166 2012-02-27 13:28:35Z willkomm $
