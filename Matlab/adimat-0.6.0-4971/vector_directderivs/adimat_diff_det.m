function varargout = adimat_diff_det(varargin)

  varargout{2} = det(varargin{2}); 
  ndd = size(varargin{1}, 1);
  A = varargin{2};
  Ainv = inv(A);
  varargout{1} = d_zeros(varargout{2});
  for d=1:ndd
      dd = ((varargout{2}) * trace(Ainv * reshape(varargin{1}(d,:), size(A))));
      varargout{1}(d,:) = dd(:);
  end
   
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
