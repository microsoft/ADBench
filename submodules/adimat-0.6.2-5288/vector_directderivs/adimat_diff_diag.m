function varargout = adimat_diff_diag(varargin)
    varargout{2} = diag(varargin{2}, varargin{3:end});
    szx = size(varargin{2});
    varargout{1} = d_zeros(varargout{2});
    for i=1:size(varargin{1}, 1)
      dd = diag(reshape(varargin{1}(i, :), szx), varargin{3:end});
      varargout{1}(i, :) = dd(:);
    end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
