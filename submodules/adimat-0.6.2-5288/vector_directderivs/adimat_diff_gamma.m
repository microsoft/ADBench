function varargout = adimat_diff_gamma(varargin)
   varargout{1} = (gamma(varargin{2}).*psi(varargin{2}).*varargin{1});
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
