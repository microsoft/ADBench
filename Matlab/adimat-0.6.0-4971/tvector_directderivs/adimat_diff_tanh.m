function varargout = adimat_diff_tanh(varargin)
  [t_s s t_c c] = adimat_taylor_sinhcosh(varargin{1}, varargin{2});
      [varargout{1} varargout{2}] = adimat_opdiff_ediv(t_s, s, t_c, c); 
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
