% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [varargout] = size(obj, varargin)
  if nargin > 1
    varargout{1} = obj.m_size(varargin{1});
  else
    if nargout <= 1
      varargout{1} = obj.m_size;
    else
      for i=1:nargout-1
        varargout{i} = obj.m_size(i);
      end
      varargout{nargout} = prod(obj.m_size(nargout:end));
    end
  end
end
% $Id: size.m 3883 2013-09-26 10:59:15Z willkomm $
