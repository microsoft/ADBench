% function r = adimat_push_cell_index(arrayVar, index1, ...)
%   Store values given by arrayVar(index1, ...) on the stack, if this
%   indexing is possible. Otherwise the whole variables has to be
%   saved, in order to restore it to previous size later.
%
% see also adimat_push, adimat_push_index, adimat_pop_cell_index
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_push_cell_index(indexVar, varargin)
  try
    adimat_push(indexVar{varargin{:}});
    adimat_push(0);
  catch
    adimat_push(indexVar);
    adimat_push(1);
  end

% $Id: adimat_push_cell_index.m 3611 2013-04-27 12:56:57Z willkomm $
