function varargout = adimat_diff_cat(varargin)
   varargout{1} = cat(varargin{1} + 1, varargin{2:2:end});
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
