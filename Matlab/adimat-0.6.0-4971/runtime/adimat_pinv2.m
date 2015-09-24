function z = adimat_pinv2(A, tol)
  if isreal(A)
    [U S V] = svd(A);
  else
    [U S V] = adimat_svd(A);
  end
  d = adimat_safediag(S);
  nign = d > tol;
  d(nign) = 1 ./ d(nign);
  d(~nign) = 0;
  T = S;
  for i=1:length(d)
    T(i,i) = d(i);
  end
  z = V * T.' * U';
end
