function varargout = adimat_diff_ifftn(varargin)
   varargout{1} = [];
  varargout{1} = varargin{1};
  for dim=1:length(size(varargin{2}))
     if nargin < 3
       n = size(varargin{2}, dim);
     else
       n = varargin{3}(dim);
     end
     if admIsOctave() && dim >= length(size(varargout{1}))
        varargout{1} = repmat(varargout{1}, adimat_repind(length(size(varargout{1})),dim+1,n))./n;
     else
        varargout{1} = ifft(varargout{1}, n, dim + 1);
     end
  end
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
