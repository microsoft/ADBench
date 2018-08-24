function varargout = adimat_diff_poly(varargin)
  [partial varargout{2}] = partial_poly(varargin{2});
  varargout{1} = d_zeros(varargout{2}(:).');
  argsz = size(varargin{2});
  ndd = size(varargin{1}, 1);
  for d=1:ndd
    dd = varargin{1}(d,:);
    varargout{1}(d,:) = partial * dd(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
