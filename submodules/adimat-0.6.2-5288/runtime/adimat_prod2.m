function z = adimat_prod2(a, dim)
  
  sz = size(a);
  
  ind = repmat({':'}, [length(sz), 1]);
  ind{dim} = 1;
  
  z = a(ind{:});
  for i=2:sz(dim)
    ind{dim} = i;
    z = z .* a(ind{:});
  end

% $Id: adimat_prod2.m 3821 2013-07-16 08:55:22Z willkomm $
