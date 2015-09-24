function varargout = adimat_diff_sqrt(varargin)
  if any(varargin{2} == 0)
    warning('adimat:derivativeError:infiniteDerivative', ...
            'The derivative of sqrt at 0 is infinite!');
  end
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_sqrt);
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
