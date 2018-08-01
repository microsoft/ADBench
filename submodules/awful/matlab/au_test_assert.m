function au_test_assert(expr1,FORCE_PRINT)
% AU_TEST_EQUAL  Test EXPR1 == true, print result
%             We call with strings rather than values to give much better
%             error messages.  The strings are evaluated in the caller's
%             context, so should behave sensibly.

if nargin == 0
  % Test
  au_test_test
  return
end

if nargin < 2
  FORCE_PRINT = 0;
else
  if ischar(FORCE_PRINT)
    FORCE_PRINT = strcmp(FORCE_PRINT, 'print');
  end
end

mfile = au_mfilename(-1);
exprval1 = evalin('caller',expr1);
symbolic = isa(exprval1,'sym');

hd = ['au_test_assert[' mfile ']:'];
err = inf;

if symbolic
    eq = all(exprval1);
elseif exprval1
    eq = 1;
else
    eq = 0;
end

if ~eq
    fprintf(2, '%s\n', [hd ' FAILED: ' expr1 ]);
else
    fprintf(1, '%s passed: %s\n', hd, expr1);
  end
end
