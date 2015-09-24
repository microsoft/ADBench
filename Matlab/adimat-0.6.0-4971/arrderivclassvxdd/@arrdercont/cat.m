% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = cat(dim, obj, varargin)
  objs = [{obj} varargin];
  areempty = cellfun(@isempty, objs);
  nempty = objs(~areempty);
  if isempty(nempty)
    obj = arrdercont([]);
  else
    obj = nempty{1};
    dds = cellfun(@(x) getder(x, dim), nempty, 'UniformOutput', false);
    obj.m_derivs = cat(dim, dds{:});
    obj.m_size = computeSize(obj);
    obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
  end
end
% $Id: cat.m 4534 2014-06-14 20:58:31Z willkomm $
