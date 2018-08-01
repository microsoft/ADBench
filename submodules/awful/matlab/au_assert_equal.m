function au_assert_equal(varargin)
% AU_ASSERT_EQUAL  Assert all(EXPR1 == EXPR2), print expr if not
%             au_assert_equal('det(M)','0'[,TOLERANCE][,VERBOSE]);
%             TOLERANCE < 0 means relative tolerance of
%              abs(TOLERANCE) * max(abs(EXPR1) + abs(EXPR2))
%             NaNs are assumed unequal, as it's consistent with isequal,
%             and it's often useful to be told there are nans...

if nargin == 0
  % unit test
  fprintf(2, '\n\n\n*** au_assert_equal test ***\n');
  writeln = @(s) fprintf(2, '%s\n', s);
  writeln('This should say PASSED:')
  au_assert_equal('sin(pi)', '0', 1e-7, 1);
  writeln('This should say PASSED:')
  a = randn(2,3);
  s = sum(a);
  au_assert_equal sum(a) s 0 1
  
  writeln('This should fail:')
  a = randn(2,3);
  s = sum(a);
  try
    au_assert_equal('sum(a)', 's+1', 0, 1);
    writeln('No exception: bad');
  catch e
    writeln('Caught exception: good.');
    writeln('Error message was:');
    disp(e.message);
  end
  
  writeln('This should fail:')
  a = randn(3,20);
  s = sum(a);
  try
    au_assert_equal('sum(a)', 's+1', 0, 1);
    writeln('No exception: bad');
  catch e
    writeln('Caught exception: good.');
    writeln('Error message should not print all values:');
    disp(e.message);
  end
  
  writeln('This should fail:')
  a = randn(3,20);
  s = sum(a);
  try
    au_assert_equal('sum(a)', 's+1', 0, 1);
    writeln('No exception: bad');
  catch e
    writeln('Caught exception: good.');
    writeln('Error message should be helpful [[[');
    disp(e.message);
    writeln(']]] that was the error message which should have been helpful:');
  end
  
  writeln('This should fail 2% of the time:');
  nfail = 0;
  for k=1:1000
    try
      au_assert_equal -p 98 0 1;
    catch e
      nfail = nfail + 1;
    end
  end
  fprintf('au_assert_equal: nfail = %d\n', nfail);
  au_test_assert nfail>5&&nfail<40
  
  
  return
end

args = varargin;
if numel(args) > 2 && strcmp(args{1}, '-p')
  apply_prob = evalin('caller', args{2})/100;
  if rand < apply_prob
    return
  end
  args = args(3:end);
end

expr1 = args{1};
expr2 = args{2};

if numel(args) < 3
  tol = 0;  % There is no other sensible default.
else
  tol = args{3};
end

if numel(args) < 4
  verbose = 0;
else
  verbose = args{4};
end

if ischar(tol)
  tol = evalin('caller', tol);
end

if ischar(verbose)
  tol = evalin('caller', verbose);
end

if ischar(expr1)
  exprval1 = evalin('caller',expr1);
else
  exprval1 = expr1;
  expr1 = 'EXP1';  % inputname(1) is slow, and almost never called with a simple input
end

if ischar(expr2)
  exprval2 = evalin('caller',expr2);
else
  exprval2 = expr2;
  expr2 = 'EXP2';
end

%if isempty(expr1) || isempty(expr2)
%  error('awful:assert', 'Expression arguments must be strings to be evaluated, or named variables');
%end

if tol < 0
  % relative tolerance
  tol = abs(tol)* max(abs(exprval1(:)) + abs(exprval2(:)));
end

% Want sizes to match exactly, even if empty
% If the caller doesn't care about size, use squeeze or (:)
if tol == 0 || isempty(exprval1) || isempty(exprval2)
  iseq = isequal(exprval1, exprval2);
  err = iseq;
else
  % tol > 0
  if all(size(exprval1) == size(exprval2))
    err = max(abs(exprval1(:) - exprval2(:)));
    iseq = err <= tol;
  else
    err= inf;
    iseq = false;
  end
end

if ~iseq
  nl = sprintf('\n');
  v1 = [expr1 '=' nl v2str(exprval1) nl];
  v2 = [expr2 '=' nl v2str(exprval2) nl];
  sval = [v1 v2];
  error('awful:assert', [sval 'au_assert_equal: FAILED: |' expr1 ' - ' expr2 '| = ' num2str(err) ' <= tol [' num2str(tol) ']']);
else
  if verbose
    disp(['au_assert_equal: PASSED: ' expr1 ' == ' expr2]);
  end
end

function s = v2str(m)
if iscell(m)
  s = ['[cell, size[' sprintf(' %d', size(m)) ']]'];
else
  s = au_mat2str(m,4,10);
end
