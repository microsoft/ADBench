function varargout = adimat_diff_interp2(varargin)
  [partial3 varargout{2}] = partial_interp2(3,varargin{1},varargin{2},varargin{4},varargin{6},varargin{8}, varargin{9:end});
  [partial4 varargout{2}] = partial_interp2(4,varargin{1},varargin{2},varargin{4},varargin{6},varargin{8}, varargin{9:end});
  [partial5 varargout{2}] = partial_interp2(5,varargin{1},varargin{2},varargin{4},varargin{6},varargin{8}, varargin{9:end});
  varargout{1} = d_zeros(varargout{2});
  ndd = size(varargin{3}, 1);
  for d=1:ndd
    dd3 = varargin{3}(d,:);
    dd4 = varargin{5}(d,:);
    dd5 = varargin{7}(d,:);
    varargout{1}(d,:) = partial3 * dd3(:) + partial4 * dd4(:) + partial5 * dd5(:);
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
