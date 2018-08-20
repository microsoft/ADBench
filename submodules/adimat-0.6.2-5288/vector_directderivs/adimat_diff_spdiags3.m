function varargout = adimat_diff_spdiags3(varargin)
   varargout{1} =     d_zeros_size([varargin{4} varargin{5}]);
    % We cannot use sparse here as no ND sparse objects exist
    for i=1:size(varargin{1}, 1)
      fm = full(spdiags(reshape(varargin{1}(i, :), size(varargin{2})), varargin{3}, varargin{4}, varargin{5}));
      varargout{1}(i, :) = fm(:);
    end;
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
