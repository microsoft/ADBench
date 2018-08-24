function varargout = adimat_diff_interp11(varargin)
  [partial_2 varargout{2}] = partial_interp1_2(varargin{2}, varargin{4});
  partial_3 = partial_interp1_3(varargin{2}, varargin{4});
  varargout{1} = d_zeros(varargout{2}(:));
  ndd = size(varargin{1}, 1);
  for d=1:ndd
    dd1 = varargin{1}(d,:);
    dd2 = varargin{3}(d,:);
    varargout{1}(d,:) = partial * dd1(:) + partial_3 * dd2(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
