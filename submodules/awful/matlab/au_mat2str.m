function s = au_mat2str(m, digits, max_elements)
% AU_MAT2STR Convert matrix to printable string
%          S = au_MAT2STR(M, DIGITS, MAX_ELEMENTS)

%          awf@microsoft.com

if nargin == 0
  %% unit test
  disp('Testing au_mat2str');
  
  a = randn(2,3,2)
  disp(au_mat2str(a, 4, 12));
  
  a = randn(2,3,2)
  disp(au_mat2str(a, 4, 11));
  
  a = rand(2,3)
  disp(au_mat2str(a, 4, 10));
  
  a = rand(2,3)
  disp(au_mat2str(a, 4, 5));
  
  disp(au_mat2str([1:4]))
  disp(au_mat2str([1:4]'))
  
  return
end

if nargin < 2
  digits = 4;
end

if nargin < 3
  max_elements = 10;
end

sz = size(m);

% More than 2D arrays get flattened and printed in the form
%  3x2x4:[1 2 3 4  ...]
if numel(sz) > 2
  s = sprintf('%s:%s', sz2str(sz), au_mat2str(m(:)', digits, max_elements));
  return
end

if numel(m) <= max_elements
  s = mat2str(m,digits);
else
  if sz(1) > 1
    if max_elements > sz(1)
      me = sz(1)*ceil(max_elements/sz(1));
      m = reshape(m(1:me), sz(1), []);
      s = mat2str(m',digits);
      s = [s(1:end-1) ' ...]'''];
      s = sprintf('%s:%s', sz2str(sz), s);
    else
      s = mat2str(m(1:min(end,max_elements)),digits);
      s = [s(1:end-1) ' ...]'];
      s = sprintf('%s:%s', sz2str(sz), s);
    end
  else
    s = mat2str(m(1:min(end,max_elements)),digits);
    s = [s(1:end-1) ' ...]'];
  end
end

function s = sz2str(sz)
s = sprintf('%d', sz(1));
s = [s sprintf('x%d', sz(2:end))];
