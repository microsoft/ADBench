function r = rows(obj)
  r = subsref(obj, struct('type', '()', 'subs', {{1}}));
  sz = size(obj);
  r = admSetDD(r, 1, sz(1));
