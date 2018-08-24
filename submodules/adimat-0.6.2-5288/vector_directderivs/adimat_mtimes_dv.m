% function d_res = adimat_mtimes_dv(d_A, B)
%
% Matrix multiply derivative object d_A times B.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function d_res = adimat_mtimes_dv(d_A, B)
  sz1 = size(d_A);
  if length(sz1) > 2
    p = sz1(3);
  else
    p = 1;
  end
  sz2 = size(B);
  d_res = d_zeros_size([sz1(2) sz2(2)]);
  for i=1:sz1(1)
    dd = reshape(d_A(i,:), [sz1(2) p]) * B;
    d_res(i,:) = dd(:).';
  end
end

% $Id: adimat_mtimes_dv.m 3308 2012-06-13 16:29:02Z willkomm $
