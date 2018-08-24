% function r = a_zeros_field(adjArrayVar, arrayVar, fieldName)
%   Zero adjoint of field expression after assignment. 
%
% see also adimat_pop_field, a_zeros, a_zeros_index
%
% This file is part of the ADiMat runtime environment
%
function r = a_zeros_field(adjArrayVar, arrayVar, fieldName)
  if isfield(arrayVar, fieldName)
    adjArrayVar.(fieldName) = a_zeros(arrayVar.(fieldName));
  else
    % There are cases where this will definitely not work
    % fprintf(1, 'a_zeros_field: removing adjoint field %s\n', fieldName);
    % adjArrayVar = rmfield(adjArrayVar, fieldName);

    % FIXME: is this really OK?
    % fprintf(1, 'a_zeros_field: not removing adjoint field %s\n', fieldName);
  end
  r = adjArrayVar;
% $Id: a_zeros_field.m 2098 2010-07-27 12:21:19Z willkomm $
