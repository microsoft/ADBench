% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = call(handle, varargin)
  which = cellfun(@isobject, varargin);
  obj = varargin{which};
  if ismember(func2str(handle), methods(obj))
    obj = handle(varargin{:});
  else
    obj = unopLoop(obj, @(dd, varargin) helper(dd, which, handle, varargin{:}), varargin{:});
    obj.m_derivs = full(obj.m_derivs);
  end
end
function r = helper(dd, which, handle, varargin)
  varargin{which} = dd;
  r = handle(varargin{:});
end
% $Id: call.m 5079 2016-04-01 09:05:13Z willkomm $
