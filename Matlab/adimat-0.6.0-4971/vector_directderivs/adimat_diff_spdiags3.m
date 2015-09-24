function varargout = adimat_diff_spdiags3(varargin)
   varargout{1} =     d_zeros_size([varargin{4} varargin{5}]);
    % We cannot use sparse here as no ND sparse objects exist
    for i=1:size(varargin{1}, 1)
      fm = full(spdiags(reshape(varargin{1}(i, :), size(varargin{2})), varargin{3}, varargin{4}, varargin{5}));
      varargout{1}(i, :) = fm(:);
    end;
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
