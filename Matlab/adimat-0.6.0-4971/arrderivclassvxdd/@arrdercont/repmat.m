% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = repmat(obj, varargin)
  repv = [varargin{:}];
  repvd = [repv 1];
  obj.m_derivs = repmat(reshape(obj.m_derivs, [obj.m_size obj.m_ndd]), repvd);
  obj.m_size = [obj.m_size ones(1, length(repv)-length(obj.m_size))] .* repv;
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
end
% $Id: repmat.m 4291 2014-05-22 11:07:49Z willkomm $
