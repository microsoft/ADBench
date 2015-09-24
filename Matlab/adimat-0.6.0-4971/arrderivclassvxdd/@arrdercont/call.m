% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = call(handle, obj, varargin)
  if ismember(func2str(handle), methods(obj))
    obj = handle(obj, varargin{:});
  else
    obj = unopLoop(obj, handle, varargin{:});
    obj.m_derivs = full(obj.m_derivs);
  end
end
% $Id: call.m 4511 2014-06-13 13:57:43Z willkomm $
