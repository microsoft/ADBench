% function r = adimat_push_index(arrayVar, index1, ...)
%   Store values given by arrayVar(index1, ...) on the stack, if this
%   indexing is possible. Otherwise the whole variables has to be
%   saved, in order to restore it to previous size later.
%
% see also adimat_push, adimat_push_cell_index, adimat_pop_index
%
% This file is part of the ADiMat runtime environment
%
function adimat_push_index(indexVar, varargin)
  try
    adimat_push(indexVar(varargin{:}));
    adimat_push(0);
  catch
    adimat_push(indexVar);
    adimat_push(1);
  end

% $Id: adimat_push_index.m 3166 2012-02-27 13:28:35Z willkomm $
