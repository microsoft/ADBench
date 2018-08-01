function col = au_linecolor(i)
% AU_LINECOLOR Return Ith line color from UI

if nargin == 0
  %% Test
  au_test_begin
  au_test_equal size(au_linecolor(1)) [1,3]
  au_test_equal size(au_linecolor(2)) [1,3]
  au_test_equal size(au_linecolor(17)) [1,3]
  au_test_equal size(au_linecolor(7)) [1,3]
  au_test_assert max(au_linecolor(7))<=1
  au_test_assert min(au_linecolor(7))>=0
  au_test_assert ~isequal(au_linecolor(1),au_linecolor(2))
  au_test_end
  return
end

cols = get(gca, 'colorOrder');
col = cols(rem(i, size(cols,1))+1, :);
