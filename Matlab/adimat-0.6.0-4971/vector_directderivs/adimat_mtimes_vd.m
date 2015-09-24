% function d_res = adimat_mtimes_vd(A, d_B)
%
% Matrix multiply A times derivative object d_B.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function d_res = adimat_mtimes_vd(A, d_B)
  sz1 = size(A);
  sz2 = size(d_B);
  if length(sz2) < 3
    sz2 = [sz2 1];
  end
  d_res = d_zeros_size([sz1(1) sz2(3)]);
  for i=1:sz2(1)
    dd = A * reshape(d_B(i,:), sz2([2 3]));
    d_res(i,:) = dd(:).';
  end
end

% $Id: adimat_mtimes_vd.m 3722 2013-06-11 14:31:02Z willkomm $
