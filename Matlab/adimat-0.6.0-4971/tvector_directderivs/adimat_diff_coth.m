function varargout = adimat_diff_coth(varargin)
  [t_s s t_c c] = adimat_taylor_sinhcosh(varargin{1}, varargin{2});
      [varargout{1} varargout{2}] = adimat_opdiff_ediv(t_c, c, t_s, s); 
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
