% function r = adimat_push_field(structVar, fieldName)
%   Store values given by structVar.(fieldName) on the stack, if this
%   field exists, and pushes a scalar 0, otherwise pushes 1.
%
% see also adimat_pop_field, adimat_push_index, adimat_push,
% adimat_store
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_push_field(structVar, fieldName)
  if isfield(structVar, fieldName)
    adimat_push(structVar.(fieldName));
    adimat_push(0);
  else
    adimat_push(1);
  end

% $Id: adimat_push_field.m 2064 2010-07-09 20:16:49Z willkomm $
