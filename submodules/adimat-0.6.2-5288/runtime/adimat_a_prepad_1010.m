function [a_a a_c] = adimat_a_prepad_1010(a,b,c,dim,a_z)
  sz = size(a);
  if length(sz) < dim
    sz = [sz ones(1,dim-length(sz))];
  end
  psz = sz;
  psz(dim) = b - sz(dim);
  sel1 = false(psz);
  sel2 = true(sz);
  sel = cat(dim, sel1, sel2);
  a_a = a_z(sel);
  a_a = reshape(a_a, sz);
  a_c = a_z(~sel);
  a_c = sum(a_c(:));
