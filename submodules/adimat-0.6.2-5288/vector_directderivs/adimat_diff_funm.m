function varargout = adimat_diff_funm(varargin)
  ndd = size(varargin{1}, 1);
  nelx = numel(varargin{2});
  if ndd < nelx
    [partial varargout{2}] = partial_funm(varargin{2}, varargin{3}, reshape(varargin{1}, [ndd, nelx]).');
    varargout{1} = reshape(partial.', [ndd size(varargin{2})]);
  else
    [partial varargout{2}] = partial_funm(varargin{2}, varargin{3});
    varargout{1} = d_zeros(varargout{2});
    argsz = size(varargin{2});
    for d=1:ndd
      dd = varargin{1}(d,:);
      varargout{1}(d,:) = partial * dd(:);
    end 
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
