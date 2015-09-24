% function r = adimat_stack_info(label, func, a, b, c)
%
% Utility function being called by statements inserted into adjoint
% code when parameter printStackInfo is set. Feel free to replace or
% modify this function. You can also change the name of the function
% being called using parameter stackInfoFunction.
%
function r = adimat_stack_info(label, func, a, b, c);
  adimat_sidestack(1, {label, func, datenum(clock()), a, b, c});
end

% $Id: adimat_stack_info_save.m 3218 2012-03-13 22:04:08Z willkomm $
