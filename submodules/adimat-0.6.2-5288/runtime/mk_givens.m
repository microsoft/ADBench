% function G = mk_givens(c, s, n, i, j)
%
% Construct the Givens-rotation U(i,j,phi), or the (i,j)-rotation, of
% order n given c = cos(phi) and s = sin(phi).
%
function G = mk_givens(c, s, n, i, j)
  G = speye(n);
  G(i,i) = c;
  G(j,j) = conj(c);
  G(i,j) = -s;
  G(j,i) = conj(s);
end
% $Id: mk_givens.m 4162 2014-05-12 07:34:49Z willkomm $
