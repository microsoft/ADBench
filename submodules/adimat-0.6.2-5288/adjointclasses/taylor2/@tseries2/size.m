function [varargout] = size(obj, varargin)
  arg2str = '';
  if length(varargin) > 0
    arg2str = [', ' num2str(varargin{1})];
  end
  if length(obj.m_series) > 0
%    fprintf('size(x%s): %s\n', arg2str, num2str(size(obj.m_series{1}, varargin{:})));
    [varargout{1:nargout}] = size(obj.m_series{1}, varargin{:});
  else
    warning('empty taylor object inquired');
    if nargout == 1
      [varargout{1}] = [0 0];
    else
      [varargout{1:nargout}] = deal(0);
    end
  end
end
