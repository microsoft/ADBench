function varargout = adimat_diff_atan2(varargin)
   varargout{1} =    d_zeros(varargin{2} + varargin{4});
   divisor = 1 ./ (varargin{4} .^2 + varargin{2} .^ 2);
   for i=1:size(varargin{1}, 1)
     tmp = varargin{1}(i, :) .* varargin{4}(:).' - varargin{2}(:).' .* varargin{3}(i, :);
     varargout{1}(i, :) = tmp .* divisor(:).';
   end
;
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
