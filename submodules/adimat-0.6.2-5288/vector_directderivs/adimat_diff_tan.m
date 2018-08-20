function varargout = adimat_diff_tan(varargin)
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_tan);
   varargout{1} =    d_zeros(varargin{2});
    for i=1:size(varargin{1}, 1)
      varargout{1}(i, :) = varargin{1}(i, :) .* sec(varargin{2}(:) .') .^ 2;
    end;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
