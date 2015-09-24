% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm
%
function obj = zerobj(obj)
  obj.m_derivs = zeros([obj.m_ndd obj.m_size]);
end
% $Id: zerobj.m 4591 2014-06-22 08:16:04Z willkomm $
