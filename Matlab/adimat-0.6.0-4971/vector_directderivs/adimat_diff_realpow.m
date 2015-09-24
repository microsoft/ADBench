function varargout = adimat_diff_realpow(varargin)
   varargout{1} = (((varargin{3}).* log(varargin{2})+ varargin{4}*((varargin{1})./ (varargin{2}))).* realpow(varargin{2}, varargin{4}));
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
