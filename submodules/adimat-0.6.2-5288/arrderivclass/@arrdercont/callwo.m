% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = callwo(handle, varargin)
  wo = find(cellfun(@isobject, varargin));
  cobj = varargin{wo};
  if ismember(func2str(handle), methods(cobj))
    obj = handle(varargin{:});
  else
    obj = unopLoopWO(handle, wo, varargin{:});
    obj.m_derivs = full(obj.m_derivs);
  end
end
% $Id: callwo.m 4796 2014-10-08 10:37:06Z willkomm $
