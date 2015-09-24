function varargout = adimat_diff_cat(varargin)
   varargout{1} = cat(varargin{1} + 1, varargin{2:2:end});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
