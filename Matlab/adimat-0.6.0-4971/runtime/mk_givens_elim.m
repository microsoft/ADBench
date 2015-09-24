function G = mk_givens_elim(H, i, j)
  n = size(H,1);
  
  if H(i,j) == 0

    G = speye(n);
  
  else
    
    r = hypot(H(i, j), H(j, j));
    c = H(j, j) ./ r;
    s = -H(i, j) ./ r;
    
    G = mk_givens(c, s, n, i, j);
    
  end
  
%  assert(isunitary(full(G)));
end
% $Id: mk_givens_elim.m 3935 2013-10-15 16:27:52Z willkomm $
