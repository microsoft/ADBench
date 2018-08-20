% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = repmat(obj, varargin)
  repv = [varargin{:}];
  repvd = [1 repv];
  obj.m_derivs = repmat(obj.m_derivs, repvd);
  obj.m_size = [obj.m_size ones(1, length(repv)-length(obj.m_size))] .* repv;
end
% $Id: repmat.m 4291 2014-05-22 11:07:49Z willkomm $
