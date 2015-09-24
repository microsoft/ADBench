function varargout = adimat_diff_mean(varargin)
    varargout{2} = mean(varargin{2}, varargin{3:end});
    varargout{1} = d_zeros(varargout{2});
    for i=1:size(varargin{1}, 1)
      dd = mean(reshape(varargin{1}(i, :), size(varargin{2})), varargin{3:end});
      varargout{1}(i, :) = dd(:).';
    end
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
