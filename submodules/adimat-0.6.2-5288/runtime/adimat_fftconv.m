function r = adimat_fftconv(a_, b_, ignored)
  if isscalar(a_) || isscalar(b_)
    r = a_ .* b_;
  else
    a = a_(:);
    b = b_(:);
    n = length(a) + length(b) - 1;
    la = length(a);
    lb = length(b);
    bo = mod(la,2) == 1 & mod(lb,2) == 1;
    ap = adimat_prepad2(adimat_postpad2(a, la + ceil(lb/2) - 1 - bo), n);
    bp = adimat_prepad2(adimat_postpad2(b, ceil(la/2) + lb - 1), n);
    r = ifftshift(ifft(fft(fftshift(ap)) .* fft(fftshift(bp))));
    % mimic fftconv output shape: when b is row, result is row
    if size(b_,2) > 1
      r = r.';
    end
  end
