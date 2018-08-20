function varargout = adimat_diff_interp13(varargin)
  [partial_1 varargout{2}] = partial_interp1_1(varargin{2}, varargin{4}, varargin{6}, varargin{7:end});
  partial_2 = partial_interp1_2(varargin{2}, varargin{4}, varargin{6}, varargin{7:end});
  partial_3 = partial_interp1_3(varargin{2}, varargin{4}, varargin{6}, varargin{7:end});
  varargout{1} = d_zeros(varargout{2});
  ndd = size(varargin{1}, 1);
  for d=1:ndd
    dd_1 = varargin{1}(d,:);
    dd_2 = varargin{3}(d,:);
    dd_3 = varargin{5}(d,:);
    varargout{1}(d,:) = partial_1 * dd_1(:) + partial_2 * dd_2(:) + partial_3 * dd_3(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
