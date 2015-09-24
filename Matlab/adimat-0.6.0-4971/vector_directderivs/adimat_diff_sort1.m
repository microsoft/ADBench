function varargout = adimat_diff_sort1(varargin)

[varargout{2}, tmp1]= sort(varargin{2});
if iscolumn(varargin{2}), 
  varargout{1}= varargin{1}(:, tmp1);
elseif isrow(varargin{2}), 
  varargout{1}= varargin{1}(:, :, tmp1);
elseif ismatrix(varargin{2}), 
  varargout{1}= varargin{1}(:, tmp1, :);
else
  dim = adimat_first_nonsingleton(varargin{2});
  ind = repmat({':'}, [1, length(size(varargin{2})) + 1]);
  ind{dim} = tmp1;
  varargout{1} = varargin{1}(ind{:});
end

end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
