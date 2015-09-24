function [varargout] = size(obj, varargin)
%  fprintf('size: %s\n', num2str(size(obj.m_series{1}, varargin{:})));
  [varargout{1:nargout}] = size(obj.m_series{1}, varargin{:});
end
