% function d_res = adimat_rdivide_dv(d_A, B)
%
% Right divide derivative object d_A by array B.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function d_res = adimat_rdivide_dv(d_A, B)
  sz1 = size(d_A);
  sz2 = size(B);
  if length(sz1) > 2
    p = sz1(3);
  else
    p = 1;
  end
  d_res = d_A;
  for i=1:sz1(1)
    dd = reshape(d_A(i,:), [sz1(2) p]) ./ B;
    d_res(i,:) = dd(:).';
  end
end

% $Id: adimat_rdivide_dv.m 3912 2013-10-09 13:48:30Z willkomm $
