function varargout = adimat_diff_squeeze(varargin)

      varargout{2} = squeeze(varargin{2});
      varargout{1} = reshape(varargin{1}, [size(varargin{1}, 1) size(varargout{2})]);
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
