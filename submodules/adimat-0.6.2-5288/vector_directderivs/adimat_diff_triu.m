function varargout = adimat_diff_triu(varargin)
[varargout{1}, varargout{2}] = d_call(@triu, varargin{1}, varargin{2}, varargin{3:end});
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
