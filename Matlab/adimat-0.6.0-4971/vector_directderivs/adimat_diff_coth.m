function varargout = adimat_diff_coth(varargin)
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_coth);
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
