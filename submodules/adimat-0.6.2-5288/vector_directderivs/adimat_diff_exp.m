function varargout = adimat_diff_exp(varargin)
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_exp);
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
