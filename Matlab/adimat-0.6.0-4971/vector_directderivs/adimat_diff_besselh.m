function varargout = adimat_diff_besselh(varargin)

      if isempty(varargin{1}) || isempty(varargin{2})
        varargout{2} = besselh(varargin{1}, varargin{2}, varargin{4});
        varargout{1} = d_zeros(varargout{2});
      else 
        [varargout{1} varargout{2}] = adimat_fdiff_vunary_sexp(varargin{3}, varargin{4}, @(x) dpartial_besselh(varargin{1}, varargin{2}, x, varargin{5:end}));
      end
      varargout{4} = 0; % backwards compatibility
      
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
