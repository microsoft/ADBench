% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = reshape(obj, varargin)
  epos = cellfun('isempty', varargin);
  if any(epos)
    eppos = find(epos);
    varargin{eppos} = prod(obj.m_size) ./ prod(cat(1, varargin{~epos}));
  end
  obj.m_size = [varargin{:}];
end
% $Id: reshape.m 4173 2014-05-13 15:04:48Z willkomm $
