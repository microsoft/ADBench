% function r = adimat_pop_index2(arrayVar, index1, index2)
%   Store values given by arrayVar(index1, ...) on the stack, if this
%   indexing is possible. Otherwise the whole variables has to be
%   saved, in order to restore it to previous size later.
%
% see also adimat_pop, adimat_pop_cell_index, adimat_push_index
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_pop_index2(r, ind1, ind2)
  whatHappened = adimat_pop;
  val = adimat_pop;
  switch whatHappened
   case 0
    r(ind1, ind2) = val;
   case 1
    r = val;
   otherwise
    error('adimat:pop_index', ...
          'Unexpected value for whatHappened: %d', whatHappened);
  end

% $Id: adimat_pop_index2.m 3167 2012-02-28 09:25:47Z willkomm $
