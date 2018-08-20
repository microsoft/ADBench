function res = numel(obj, varargin)
%  fprintf('tseries2.numel: %s\n', num2str(size(obj)));
%  disp(varargin);
  if nargin < 2
    res = prod(size(obj));
    return
  end
  if ischar(varargin{1}) && varargin{1}==':'
    res = obj.m_ord(1);
  else
    res = length(varargin{1});
  end
%  fprintf('tseries2.numel: %d\n', res);
end
