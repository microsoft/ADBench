function varargout = adimat_diff_triu(varargin)
[varargout{1}, varargout{2}] = d_call(@triu, varargin{1}, varargin{2}, varargin{3:end});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
