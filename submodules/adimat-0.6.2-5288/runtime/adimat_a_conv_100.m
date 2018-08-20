function a_a = adimat_a_conv_100(a, b, mode, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, mode);
  a_a = a_adimat_fftconv2_1(a, b, a_ys);
