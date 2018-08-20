function varargout = adimat_diff_circshift(varargin)
   varargout{1} = circshift(varargin{1}, [0; varargin{3}(:)]);
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
