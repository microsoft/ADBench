function varargout = adimat_diff_sparse3(varargin)

varargout{2} = sparse(varargin{1}, varargin{2}, varargin{4});
m = max(varargin{1});
n = max(varargin{2});
ndd = size(varargin{3}, 1);
varargout{1} = d_zeros_size([m n]);
for i=1:ndd
   dd = sparse(varargin{1}, varargin{2}, varargin{3}(i,:));
   varargout{1}(i,:) = dd(:);
end
      
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
