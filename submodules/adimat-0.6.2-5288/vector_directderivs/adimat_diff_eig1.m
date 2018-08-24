function varargout = adimat_diff_eig1(varargin)
[tmp1, tmp2]=eig(varargin{2}); 
varargout{2} = diag(tmp2); 
tmp3 = inv(tmp1); 
varargout{1} = adimat_mtimes_dv(adimat_mtimes_vd(tmp3, varargin{1}), tmp1);
varargout{1} = adimat_diff_diag(varargout{1}, varargin{2});
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
