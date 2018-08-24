function [obj] = prod(obj, k)
  if nargin == 2
    obj = adimat_prod2(obj, k);
  else
    obj = adimat_prod1(obj);
  end
end
