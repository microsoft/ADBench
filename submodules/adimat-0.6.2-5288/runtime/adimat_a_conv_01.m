function a_b = adimat_a_conv_01(a, b, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, 'full');
  a_b = a_adimat_fftconv2_2(a, b, a_ys);
