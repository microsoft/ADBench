function varargout = adimat_diff_linspace1(varargin)

        varargout{2} = linspace(varargin{2}, varargin{4}, varargin{5});
        lp01 = linspace(0, 1, varargin{5});
        % varargin{1} and varargin{3} are derivatives of scalars!
        varargout{1} = varargin{3} * lp01 + varargin{1} * fliplr(lp01);
        varargout{1} = reshape(varargout{1}, [size(varargout{1}, 1) size(varargout{2})]);

      
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
