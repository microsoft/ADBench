function a_a = adimat_a_conv_10(a, b, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, 'full');
  a_a = a_adimat_fftconv2_1(a, b, a_ys);
