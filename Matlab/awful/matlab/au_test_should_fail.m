function au_test_should_fail(expr1)
% AU_TEST_SHOULD_FAIL Test that EXPR throws an error


if nargin == 0
  % Test
  au_test_should_fail rand()()
  au_test_should_fail disp('')
  disp('^^ should_fail should have failed here')
  return
end

mfile = au_mfilename(-1);
hd = ['au_test_should_fail[' mfile ']:'];

try
    evalin('caller',expr1);
    % Got here -- it didn't fail....
    fprintf(2, '%s\n', [hd ' FAILED: ' expr1 ' should have thrown']);
    
catch e
    disp([hd ' passed: ' expr1 ' threw exception "' e.message '"']);
end
