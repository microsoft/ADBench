% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function [sz] = computeSize(obj)
  szd = size(obj.m_derivs);
  if obj.m_ndd == 1
    sz = szd;
  else
    sz = szd(1:end-1);
  end
  if length(sz) < 2
    if sz(1) == 0
      sz = [sz 0];
    else
      sz = [sz 1];
    end
  end
  while sz(end) == 1 && length(sz) > 2
    sz = sz(1:end-1);
  end
end
% $Id: computeSize.m 4291 2014-05-22 11:07:49Z willkomm $
