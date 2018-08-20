% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm
%
function obj = zerobj(obj)
  obj.m_derivs = zeros([prod(obj.m_size) obj.m_ndd]);
end
% $Id: zerobj.m 4592 2014-06-22 08:17:05Z willkomm $
