function varargout = adimat_diff_cumsum1(varargin)
   varargout{1} = cumsum(varargin{1}, adimat_first_nonsingleton(varargin{2}) + 1);
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
