function varargout = adimat_diff_interp1q(varargin)
  [partial varargout{2}] = partial_interp1q(varargin{2}, varargin{4}, varargin{6});
  varargout{1} = d_zeros(varargout{2});
  ndd = size(varargin{3}, 1);
  for d=1:ndd
    dd = varargin{3}(d,:);
    varargout{1}(d,:) = partial * dd(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
