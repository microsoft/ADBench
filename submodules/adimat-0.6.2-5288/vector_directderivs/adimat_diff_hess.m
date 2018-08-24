function varargout = adimat_diff_hess(varargin)

        [varargout{1}, ~, varargout{3}] = d_adimat_hess(varargin{1}, varargin{2});
        [varargout{2} varargout{4}] = hess(varargin{2});
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
