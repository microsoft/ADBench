function varargout = adimat_diff_fft2(varargin)
   varargout{1} = [];
  if nargin < 3
    m = size(varargin{2}, 1);
  else
    m = varargin{3};
  end
  if nargin < 4
    n = size(varargin{2}, 2);
  else
    n = varargin{4};
  end
  varargout{1} = fft(varargin{1}, m, 2);
  if admIsOctave() && 3 > length(size(varargout{1}))
    varargout{1} = repmat(varargout{1}, adimat_repind(length(size(varargout{1})),3,n));
  else
    varargout{1} = fft(varargout{1}, n, 3);
  end
      ;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
