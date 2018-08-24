% function r = adimat_pop_field(structVar, fieldName)
%   Restore values given by structVar.(fieldName) from the stack, if this
%   field did exist, otherwise it is removed. 
%
% see also adimat_push_field, a_zeros_field, adimat_push, adimat_pop
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_pop_field(fieldVar, fieldName)
  whatHappened = adimat_pop;
  r = fieldVar;
  switch whatHappened
   case 0
    val = adimat_pop;
    r.(fieldName) = val;
   case 1
    % There are cases where this will definitely not work
    %    fprintf(1, 'adimat_pop_field: removing field %s\n', fieldName);
    %    r = rmfield(r, fieldName);

    % FIXME: is this really OK (not removing the field)?
    % fprintf(1, 'adimat_pop_field: not removing field %s\n', fieldName);
   otherwise
    error('adimat:pop_field', ...
          'Unexpected value for whatHappened: %d', whatHappened);
  end
  
% $Id: adimat_pop_field.m 2098 2010-07-27 12:21:19Z willkomm $
