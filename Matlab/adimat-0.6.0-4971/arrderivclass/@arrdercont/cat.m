% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = cat(dim, varargin)
  areempty = cellfun(@isempty, varargin);
  nempty = varargin(~areempty);
  if isempty(nempty)
    obj = arrdercont([]);
  else
    dds = cellfun(@(x) full(x.m_derivs), nempty, 'UniformOutput', false);
    obj = arrdercont(nempty{1});
    obj.m_derivs = cat(dim + 1, dds{:});
    obj.m_size = computeSize(obj);
  end
end
% $Id: cat.m 4881 2015-02-15 21:01:00Z willkomm $
