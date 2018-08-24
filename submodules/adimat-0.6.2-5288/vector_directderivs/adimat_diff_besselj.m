function varargout = adimat_diff_besselj(varargin)

      if isempty(varargin{1}) || isempty(varargin{3})
        varargout{2} = besselj(varargin{1}, varargin{3});
        varargout{1} = d_zeros(varargout{2});
      else 
        [varargout{1} varargout{2}] = adimat_fdiff_vunary_sexp(varargin{2}, varargin{3}, @(x) dpartial_besselj(varargin{1}, x, varargin{4:end}));
      end
      varargout{4} = 0; % backwards compatibility
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
