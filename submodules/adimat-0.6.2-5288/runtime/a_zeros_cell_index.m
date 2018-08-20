% function r = a_zeros_cell_index(adjArrayVar, arrayVar, index1, ...)
%   Zero adjoint of index expression after assignment. If the forward
%   assignment changed the size of the array variable, then maybe
%   resize the adjoint here, undoing the size change.  If the size did
%   not change then fill the indexed adjoint with a_zeros.
%
% see also adimat_push_cell_index, adimat_pop_cell_index, a_zeros,
% a_zeros_index
%
% This file is part of the ADiMat runtime environment
%
function r = a_zeros_cell_index(adjArrayVar, arrayVar, varargin)
  szAdj = size(adjArrayVar);
  szVar = size(arrayVar);
  if isequal(szAdj, szVar) || ...
        ((szAdj(1) == 1 || szAdj(2) == 1) && isequal(szAdj, szVar([2 1])))
    r = adjArrayVar;
    r{varargin{:}} = a_zeros(arrayVar{varargin{:}});
  else
    test2 = zeros(szVar);
    test2(varargin{:}) = 1;
    test3 = ones(szVar);
    topIndex = num2cell(szAdj);
    test3(topIndex{:}) = 0;
    if ~isequal(size(test3), szAdj)
      error('adimat:runtime:a_zeros_index', '%s', ...
            'test selection wrong size');
    end
    r = adjArrayVar;
    selwrit = test2 == 1;
    selold = test3 == 1;
    r{selwrit} = a_zeros(r(selwrit));
    r = reshape(r(selold), szVar);
  end
% $Id: a_zeros_cell_index.m 2195 2010-08-31 15:32:46Z willkomm $
