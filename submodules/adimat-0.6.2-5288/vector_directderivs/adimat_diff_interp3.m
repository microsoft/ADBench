function varargout = adimat_diff_interp3(varargin)
  [partial varargout{2}] = partial_interp3(varargin{1}, varargin{2}, varargin{3}, varargin{5}, varargin{6}, varargin{7}, varargin{8}, varargin{9:end});
  varargout{1} = d_zeros(varargout{2});
  ndd = size(varargin{4}, 1);
  for d=1:ndd
    dd = varargin{4}(d,:);
    varargout{1}(d,:) = partial * dd(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
