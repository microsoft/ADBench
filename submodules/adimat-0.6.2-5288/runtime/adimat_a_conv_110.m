function [a_a, a_b] = adimat_a_conv_110(a, b, mode, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, mode);
  [a_a, a_b] = a_adimat_fftconv2(a, b, a_ys);
