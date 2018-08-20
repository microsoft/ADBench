% function r = adimat_push_index2(arrayVar, index1, index2)
%   Store values given by arrayVar(index1, ...) on the stack, if this
%   indexing is possible. Otherwise the whole variables has to be
%   saved, in order to restore it to previous size later.
%
% see also adimat_push, adimat_push_cell_index, adimat_pop_index
%
% This file is part of the ADiMat runtime environment
%
function adimat_push_index2(indexVar, ind1, ind2)
  try
    adimat_push(indexVar(ind1, ind2));
    adimat_push(0);
  catch
    adimat_push(indexVar);
    adimat_push(1);
  end

% $Id: adimat_push_index2.m 3167 2012-02-28 09:25:47Z willkomm $
