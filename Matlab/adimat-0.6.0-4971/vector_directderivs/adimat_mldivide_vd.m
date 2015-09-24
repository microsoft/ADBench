% function d_res = adimat_mldivide_vd(A, d_B)
%
% Matrix left divide A by derivative object d_B.
%
% Copyright 2014 Johannes Willkomm
function r = adimat_mldivide_vd(v, w)
  [~, n] = size(v);
  [ndd m p] = size(w);
  r = permute(reshape(v \ reshape(permute(w, [2 1 3]), [m ndd.*p]), [n ndd p]),[2,1,3]);
end

% $Id: adimat_mldivide_vd.m 4355 2014-05-28 11:10:28Z willkomm $
