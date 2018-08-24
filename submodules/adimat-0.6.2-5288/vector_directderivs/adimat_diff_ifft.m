function varargout = adimat_diff_ifft(varargin)
   varargout{1} = [];
  if ischar(varargin{end})
     methodArg = varargin(end);
     varargin = varargin(1:end-1);
  else
     methodArg = {};
  end
  nargs = length(varargin);
  if nargs < 4
    if isscalar(varargin{2})
      dim = 2; 
    else
      dim = adimat_first_nonsingleton(varargin{2});
    end
  else
    dim = varargin{4};
  end
  if nargs < 3
    n = size(varargin{2}, dim);
  else
    n = varargin{3};
  end
  if admIsOctave() && dim+1 > length(size(varargin{1}))
    varargout{1} = repmat(varargin{1}, adimat_repind(length(size(varargin{1})), dim+1,n)) ./ n;
  else
    varargout{1} = ifft(varargin{1}, n, dim + 1, methodArg{:});
  end
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
