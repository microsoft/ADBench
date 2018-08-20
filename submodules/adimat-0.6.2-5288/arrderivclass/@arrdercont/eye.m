function r = eye(n, dummy)
  if isa(n, 'arrdercont')
    ndd = n.m_ndd;
    n = admGetDD(n, 1);
  else
    ndd = option('ndd');
  end
  I = eye(n);
  r = arrdercont(I, ndd);
  for k=1:ndd
    r = admSetDD(r, k, I);
  end
