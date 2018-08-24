function a_b = adimat_a_conv_010(a, b, mode, a_y)
  a_ys = adimat_expand_conv_adjoint(a, b, a_y, mode);
  a_b = a_adimat_fftconv2_2(a, b, a_ys);
