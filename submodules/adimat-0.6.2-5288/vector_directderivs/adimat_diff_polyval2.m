function varargout = adimat_diff_polyval2(varargin)
if all(size(varargin{2})>1)
warning('ADiMat:polyval_matrix', 'polyval(p,x): p is a matrix. In the computation only its first column is used.');
varargout{1}= ((varargin{1})*repmat(varargin{4},size((varargin{2})')).^repmat((length(varargin{2})-1:-1:0)', size(varargin{4}))+ polyval(polyder(varargin{2}(:,1)),varargin{4},varargin{5:end}).*(varargin{3}));
[varargout{2}, varargout{4}]= polyval(varargin{2}, varargin{4}, varargin{5:end});
else
varargout{1}= ((varargin{1})*repmat(varargin{4},size((varargin{2})')).^repmat((length(varargin{2})-1:-1:0)', size(varargin{4}))+ polyval(polyder(varargin{2}),varargin{4},varargin{5:end}).*(varargin{3}));
[varargout{2}, varargout{4}]= polyval(varargin{2}, varargin{4}, varargin{5:end});
end
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
