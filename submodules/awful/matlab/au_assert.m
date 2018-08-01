function au_assert(varargin)
% AU_ASSERT  Assert all(EXPR), print expr if not
%             au_assert('det(M) > 0');

if nargin == 0
  au_test_assert
  return
end

if nargin == 3
  % Check for switch
  if strcmp(varargin{1}, '-p')
    apply_probability = num2str(varargin{2});
    if rand < apply_probability
      return
    end
    expr = varargin{3};
  else
    error
  end
else
  au_assert_equal nargin 1
  expr = varargin{1};
end

exprval = evalin('caller',expr);
if ~all(exprval(:))
  error(['au_assert: FAILED: ' expr]);
end
