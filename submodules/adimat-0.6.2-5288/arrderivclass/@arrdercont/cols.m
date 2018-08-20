function r = cols(obj)
  r = obj(1);
  sz = size(obj);
  r = admSetDD(r, 1, sz(2));
