function [l] = adimat_eig2x2(A)
  a = A(1, 1);
  b = A(1, 2);
  c = A(2, 1);
  d = A(2, 2);

  t = d*d-2*a*d+4*b*c+a*a;
  if t == 0
    sq = 0;
  else
    sq = sqrt(t);
  end
  
  l = zeros(2,1);
  l(1) = -(sq-d-a)/2.0;
  l(2) = (sq+d+a)/2.0;
end
