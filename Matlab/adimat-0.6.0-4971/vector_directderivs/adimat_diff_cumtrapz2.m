function varargout = adimat_diff_cumtrapz2(varargin)
   varargout{1} = adimat_d_cumtrapz(varargin{1}, varargin{2}, d_zeros(varargin{3}), varargin{3});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
