function varargout = adimat_diff_hypot(varargin)
 
  varargout{2} = hypot(varargin{2}, varargin{4});
  divisor = 1 ./ varargout{2};
  for i=1:size(varargin{1}, 1)
    tmp = varargin{1}(i, :) .* varargin{2}(:).' + varargin{4}(:).' .* varargin{3}(i, :);
    varargout{1}(i, :) = tmp .* divisor(:).';
  end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
