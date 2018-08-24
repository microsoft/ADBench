function varargout = adimat_diff_fft(varargin)
   varargout{1} = [];
  if nargin < 4
    if isscalar(varargin{2})
      dim = 2; 
    else
      dim = adimat_first_nonsingleton(varargin{2});
    end
  else
    dim = varargin{4};
  end
  if nargin < 3
    n = size(varargin{2}, dim);
  else
    n = varargin{3};
  end
  if admIsOctave() && dim+1 > length(size(varargin{1}))
    varargout{1} = repmat(varargin{1}, adimat_repind(length(size(varargin{1})), dim+1,n));
  else
    varargout{1} = fft(varargin{1}, n, dim + 1);
  end
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
