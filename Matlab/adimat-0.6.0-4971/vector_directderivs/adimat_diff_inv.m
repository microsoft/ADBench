function varargout = adimat_diff_inv(varargin)

  varargout{2} = inv(varargin{2}); 
  ndd = size(varargin{1}, 1);
  varargout{1} = d_zeros(varargout{2});
  for d=1:ndd
      dd = (varargout{2}) * (- reshape(varargin{1}(d,:), size(varargin{2}))*varargout{2});
      varargout{1}(d,:) = dd(:);
  end
      
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
