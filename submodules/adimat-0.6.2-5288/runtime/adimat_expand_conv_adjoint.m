function a_ys = adimat_expand_conv_adjoint(a, b, a_y, mode)
  switch mode
    case 'full'
      a_ys = a_y;
    case 'same'
      n = length(a) + length(b) - 1;
      a_ys = a_zeros(zeros(1, n));
      ld = n - length(a);
      i0 = max(1,ceil((ld+2)/2));
      a_ys(i0:i0+length(a)-1) = a_y;
    case 'valid'
      n = length(a) + length(b) - 1;
      a_ys = a_zeros(zeros(1, n));
      on = max(0, length(a) - length(b) + 1);
      ld = n - on;
      i0 = max(1,ceil((ld+1)/2));
      a_ys(i0:i0+on-1) = a_y;
  end
  % reshape to shape that fftconv would return:
  if isscalar(a)
    osz = size(b);
  elseif isscalar(b)
    osz = size(a);
  else
    if size(b,2) == 1
      osz = [prod(size(a_ys)) 1];
    else
      osz = [1 prod(size(a_ys))];
    end
  end
  a_ys = reshape(a_ys, osz);
