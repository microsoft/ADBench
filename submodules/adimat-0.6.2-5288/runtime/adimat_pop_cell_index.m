% function r = adimat_pop_cell_index(arrayVar, index1, ...)
%   Store values given by arrayVar(index1, ...) on the stack, if this
%   indexing is possible. Otherwise the whole variables has to be
%   saved, in order to restore it to previous size later.
%
% see also adimat_pop, adimat_pop_index, adimat_push_cell_index
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_pop_cell_index(indexVar, varargin)
  [whatHappened val] = adimat_pop;
  switch whatHappened
   case 0
    r = indexVar;
    r{varargin{:}} = val;
   case 1
    r = val;
   otherwise
    error('adimat:pop_index', ...
          'Unexpected value for whatHappened: %d', whatHappened);
  end

% $Id: adimat_pop_cell_index.m 3611 2013-04-27 12:56:57Z willkomm $
