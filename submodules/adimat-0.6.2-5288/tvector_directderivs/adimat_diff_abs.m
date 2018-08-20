function varargout = adimat_diff_abs(varargin)

        varargout{2} = abs(varargin{2});
        factor = sign(varargin{2});
        [nord, ndd, nelx] = size(varargin{1});
        factor = reshape(factor, [ 1 1 nelx ]);
        factor = repmat(factor, [ nord ndd 1 ]);
        factor = reshape(factor, [ nord ndd size(varargin{2}) ]);
        varargout{1} = varargin{1} .* factor;
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
