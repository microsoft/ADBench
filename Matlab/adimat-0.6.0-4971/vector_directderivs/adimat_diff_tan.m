function varargout = adimat_diff_tan(varargin)
  [varargout{1} varargout{2}] = adimat_fdiff_vunary(varargin{1}, varargin{2}, @dpartial_tan);
   varargout{1} =    d_zeros(varargin{2});
    for i=1:size(varargin{1}, 1)
      varargout{1}(i, :) = varargin{1}(i, :) .* sec(varargin{2}(:) .') .^ 2;
    end;
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
