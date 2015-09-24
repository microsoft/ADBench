function last = end(obj, k, n)
  sz = size(obj.m_series{1});
  if k == n
    if k == 1
      last = prod(sz);
    else
      d = length(sz);
      last = prod(sz(k:d));
    end
  else
    last = sz(k);
  end
end
