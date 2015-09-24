function x = au_deep_vectorize(obj, varargin)
% AU_DEEP_VECTORIZE Flatten arbitrary structure/cell a linear vector x.
%         x = au_deep_vectorize(obj)
%         obj1 = au_deep_unvectorize(obj, x) % use obj as a template
%         au_assert_equal obj obj1

%  Killed the unvec return.  It was slow
%         Two different versions of the unvectorize function.
%         If you ask for a second output argument you'll get a function
%         handle which will unvectorize the argument.   But in 2015, this
%         is a perf nightmare.  If the struct is more than say 500 deep,
%         you'll just hang your machine incorrigibly.  In that case, pass a
%         second argument which is the basename of the m-file you want
%         created which will implement the correspomding unvec.  In many
%         cases this is faster and still ok.

% awf, aug13

if nargin == 0
  %% Test
  au_test_begin
  
  a = 2;
  b.a = randn(2,3,4);
  b.b = [1 1];
  c = {randn(3,1), randn(1,1,2)};
  b.c.d = c;
  d = cell(2,2,3);
  b1 = b;
  b1.b = [2 3];
  obj1 = {a,{b,c;c,b1}};
  
  x1  = au_deep_vectorize(obj1);
  obj1a = au_deep_unvectorize(obj1, x1);
  
  au_test_equal obj1 obj1a 0 1
  
  obj2 = struct;
  obj2(1).a = 1;
  obj2(2).a = 1.2;
  obj2(3).a = 2;
  x1 = au_deep_vectorize(obj2);
  obj2a  = au_deep_unvectorize(obj2, x1);
  
  % fprintf('x len = %d\n', length(x1));
  au_test_equal obj2a obj2
  
  sx = sym('x', size(x1));
  au_test_assert isa(sx,'sym')
  obj2b = au_deep_unvectorize(obj2, sx);
  au_test_assert isa(obj2b(1).a,'sym')
  
  au_test_end
  return
end

sz = size(obj);

if iscell(obj)
  % Cell array
  unvec = '';
  for k=1:numel(obj)
    xk = au_deep_vectorize(obj{k}, varargin{:});
    nk = numel(xk);
    if k==1
      x = xk; % preserve datatype
      n = 0;
    else
      n = numel(x);
      x = [x; xk];
    end
  end
elseif isstruct(obj)
  fields = fieldnames(obj);
  if numel(obj) > 1
    % Struct array
    x = au_deep_vectorize(struct2cell(obj));
  else
    % Singleton struct
    % For unvec, create a struct call of the form
    % struct('field1', unvecs{1}(x(1:4)), 'field2', unvecs{2}(x(5:8)))
    for k = 1:length(fields)
      objk = obj.(fields{k});
      xk = au_deep_vectorize(objk);
      nk = length(xk);
      if k == 1
        % preserve type
        if islogical(xk)
          out = false(10000,1);
        else
          out = zeros(10000,1, 'like', xk);
        end
        out(1:nk) = xk;
        n = 0;
      else
        out(n+(1:nk)) = xk;
      end
      n = n + nk;
    end
    x = out(1:n);
    %x_old = cell2mat(au_map(@(x) au_deep_vectorize(obj.(x)), fieldnames(obj)));
    %au_assert_equal x x_old
  end
else
  % Doesn't make sense for non-numeric types, and until I understand
  % cat(1, uint(9), 9.1), forcing it to double.
  % BUT SLOW, so check at random.
  if rand > .99, au_assert isnumeric(obj)||islogical(obj), end
  x = obj(:);
end
