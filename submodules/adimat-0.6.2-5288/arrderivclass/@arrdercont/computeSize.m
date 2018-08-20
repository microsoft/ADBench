% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [sz] = computeSize(obj)
  szd = size(obj.m_derivs);
  sz = szd(2:end);
  if length(sz) < 2
    if sz(1) == 0
      sz = [sz 0];
    else
      sz = [sz 1];
    end
  end
end
% $Id: computeSize.m 3862 2013-09-19 10:50:56Z willkomm $
