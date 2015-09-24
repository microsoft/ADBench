% function z = adimat_bsxfun(handle, a, b)
%
% ADiMat replacement function for bsxfun
%
% Copyright (C) 2015 Johannes Willkomm
function z = adimat_bsxfun(handle, a, b)
  sza = size(a);
  szb = size(b);
  if length(szb) > length(sza)
    sza = [sza ones(1, length(szb)-length(sza))];
  elseif length(sza) > length(szb)
    szb = [szb ones(1, length(sza)-length(szb))];
  end
  to_repa = sza == 1 & szb ~= 1;
  repinda = ones(1, length(sza));
  repinda(to_repa) = szb(to_repa);
  a = repmat(a, repinda);

  to_repb = szb == 1 & sza ~= 1;
  repindb = ones(1, length(szb));
  repindb(to_repb) = sza(to_repb);
  b = repmat(b, repindb);
  
  z = handle(a, b);
end
% $Id: adimat_bsxfun.m 4951 2015-03-02 13:11:07Z willkomm $
