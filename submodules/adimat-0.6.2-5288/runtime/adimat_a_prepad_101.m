function [a_a a_c] = adimat_a_prepad_101(a,b,c,a_z)
  dim = adimat_first_nonsingleton(a);
  [a_a a_c] = adimat_a_prepad_1010(a,b,c,dim,a_z);
