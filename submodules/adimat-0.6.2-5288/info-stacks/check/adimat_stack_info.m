% function r = adimat_stack_info(label, func, a, b, c)
%
% Utility function being called by statements inserted into adjoint
% code when parameter printStackInfo is set. Feel free to replace or
% modify this function. You can also change the name of the function
% being called using parameter stackInfoFunction.
%
function r = adimat_stack_info(label, func, a, b, c);
%  fprintf(admLogFile('stackInfo'), '%s %s: %d %g %g\n', label, func, a, b, c);
  if strncmp('rec_', func, 4)
    adimat_sidestack(1, {func, a, b, c});
  elseif strncmp('ret_', func, 4)
    entry = adimat_sidestack(0);
    if ~strcmp(entry{1}(5:end), func(5:end))
      error('wrong function call order!?');
    end
    if entry{2} ~= a
      error('wrong function stack size: at this point in %s it was %d',...
            entry{1}, entry{2});
    end
  end
end

% $Id: adimat_stack_info_check.m 3218 2012-03-13 22:04:08Z willkomm $
