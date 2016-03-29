function au_test_regexp(str, regex)
% AU_TEST_REGEXP  Test that string matches regex 
%             au_test_regexp(sprintf('%.3f', 4), '\d+\.\d')

if nargin == 0
  % Test
  au_test_test
  return
end

mfile = au_mfilename(-1);
hd = ['au_test_regexp[' mfile ']:'];

str_to_print = regexprep(str, '\n', '\\n');
if length(str_to_print) > 80
  str_to_print = [str_to_print(1:77) '...'];
end    
if isempty(regexp(str, regex, 'once'))
  fprintf(2, '%s\n', [hd ' FAILED: regex /' regex '/ not satisfied by [' str ']']);
else
  disp([hd ' passed: /' regex '/ ~ [' str_to_print ']']);
end
