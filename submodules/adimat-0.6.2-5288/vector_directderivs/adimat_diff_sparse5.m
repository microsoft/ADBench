function varargout = adimat_diff_sparse5(varargin)

varargout{2} = sparse(varargin{1}, varargin{2}, varargin{4});
m = varargin{5};
n = varargin{6};
ndd = size(varargin{3}, 1);
varargout{1} = d_zeros_size([m n]);
for i=1:ndd
   dd = sparse(varargin{1}, varargin{2}, varargin{3}(i,:));
   varargout{1}(i,:) = dd(:);
end
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
