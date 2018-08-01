function au_bsx_test
% BSX_TEST Test the bsx class

% "Import" the short name
bsx = @au_bsx;

row = bsx(rand(1,3));
col = bsx(rand(5,1));

m = ones(5,3); 

au_test_equal col.*row bsxfun(@times,col.val,row.val)
au_test_equal col+row bsxfun(@plus,col.val,row.val)
au_test_equal max(col,row) bsxfun(@max,col.val,row.val)
au_test_equal min(col,row) bsxfun(@min,col.val,row.val)

au_test_equal m.*row bsxfun(@times,m,row.val)
au_test_equal m+row bsxfun(@plus,m,row.val)
au_test_equal max(m,row) bsxfun(@max,m,row.val)
au_test_equal min(m,row) bsxfun(@min,m,row.val)

au_test_equal col.*m bsxfun(@times,col.val,m)
au_test_equal col+m bsxfun(@plus,col.val,m)
au_test_equal max(col,m) bsxfun(@max,col.val,m)
au_test_equal min(col,m) bsxfun(@min,col.val,m)
%#ok<*NASGU> unused vars in calls to au_test_equal
