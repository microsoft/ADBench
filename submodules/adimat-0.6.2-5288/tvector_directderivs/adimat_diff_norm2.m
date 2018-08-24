function varargout = adimat_diff_norm2(varargin)

        varargout{2} = norm(varargin{2}, varargin{4});
        [t_absx absx] = adimat_diff_abs(varargin{1}, varargin{2});
        [t_pabsx pabsx] = adimat_opdiff_epow(t_absx, absx, varargin{3}, varargin{4});
        [t_pabsx pabsx] = adimat_diff_sum1(t_pabsx, pabsx);
        [t_pinv pinv] = adimat_opdiff_ediv_left(1, varargin{3}, varargin{4});
        [varargout{1} varargout{2}] = adimat_opdiff_epow(t_pabsx, pabsx, t_pinv, pinv);
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
