% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm 
function obj = triu(obj, k)
  if nargin<2
    k = 0;
  end
  for i=1:min(obj.m_size(1)+k, obj.m_size(2))
    obj.m_derivs(:,max(1,i+1-k):end,i) = 0;
  end
end
% $Id: triu.m 4959 2015-03-03 08:35:00Z willkomm $
