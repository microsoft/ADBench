function varargout = adimat_diff_cross1(varargin)

  varargout{2} = cross(varargin{2}, varargin{4});
  varargout{1} = d_zeros(varargout{2});
  varargout{1}(:, 1) = varargin{1}(:, 2) .* varargin{4}(3) + varargin{2}(2) .* varargin{3}(:, 3) ...
                        - (varargin{1}(:, 3) .* varargin{4}(2) + varargin{2}(3) .* varargin{3}(:, 2));
  varargout{1}(:, 2) = varargin{1}(:, 3) .* varargin{4}(1) + varargin{2}(3) .* varargin{3}(:, 1) ...
                        - (varargin{1}(:, 1) .* varargin{4}(3) + varargin{2}(1) .* varargin{3}(:, 3));
  varargout{1}(:, 3) = varargin{1}(:, 1) .* varargin{4}(2) + varargin{2}(1) .* varargin{3}(:, 2) ...
                        - (varargin{1}(:, 2) .* varargin{4}(1) + varargin{2}(2) .* varargin{3}(:, 1));
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
