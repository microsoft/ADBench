function varargout = adimat_diff_norm1(varargin)

        [t_p2x p2x] = adimat_opdiff_epow_right(varargin{1}, varargin{2}, 2);
        [t_sp2x sp2x] = adimat_diff_sum1(t_pabsx, pabsx);
        [varargout{1} varargout{2}] = adimat_opdiff_epow_right(t_sp2x, sp2x, 0.5);
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
