% function r = adimat_prepad(a,l,c)
%
% Mimic the function prepad, which is available in Octave, but not in MATLAB
%
% (c) 2018 Johannes Willkomm
function r = adimat_postpad(a,l,c,dim)
  psz = size(a);
  psz(dim) = l - psz(dim);
  pa = repmat(c, psz);
  r = cat(dim, a, pa);
