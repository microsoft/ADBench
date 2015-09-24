function varargout = adimat_diff_eig1(varargin)
[tmp1, tmp2]=eig(varargin{2}); 
varargout{2} = diag(tmp2); 
tmp3 = inv(tmp1); 
varargout{1} = adimat_mtimes_dv(adimat_mtimes_vd(tmp3, varargin{1}), tmp1);
varargout{1} = adimat_diff_diag(varargout{1}, varargin{2});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
