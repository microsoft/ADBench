% function res = adimat_missing_derivative_value()
%
% Return a number that represents the derivative at a point where it
% is not defined. This function returns 0. 
% 
% Typically, when the runtime functions detect a case where a
% derivative is to be evaluated at a point where no derivative exists,
% a zero derivative is created and the result of this function is
% added to that.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function res = adimat_missing_derivative_value()
  answer = admGetPref('missing_derivative_value');
  switch answer
   case '0'
    res = 0;
   case 'NaN'
    res = nan();
   case 'NA'
    res = NA();
  end
end
% $Id: adimat_missing_derivative_value.m 3746 2013-06-13 11:11:13Z willkomm $
