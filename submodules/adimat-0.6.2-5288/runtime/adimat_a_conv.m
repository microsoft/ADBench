function [a_a, a_b] = adimat_a_conv(a, b, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, 'full');
  [a_a, a_b] = a_adimat_fftconv2(a, b, a_ys);
