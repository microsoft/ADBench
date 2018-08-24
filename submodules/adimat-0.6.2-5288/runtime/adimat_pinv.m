function z = adimat_pinv(A)
  tol = max(size(A)) * norm(A) * eps(class(A));
  z = adimat_pinv2(A, tol);
end
