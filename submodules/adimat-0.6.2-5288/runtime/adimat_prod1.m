function z = adimat_prod1(a)

  dim = adimat_first_nonsingleton(a);
  
  z = adimat_prod2(a, dim);

% $Id: adimat_prod1.m 3739 2013-06-12 16:49:42Z willkomm $
