function varargout = adimat_diff_spdiags4(varargin)
[varargout{2}, varargout{4}]=spdiags(varargin{2}); 
varargout{1}= call(@spdiags, varargin{1}, varargout{4});
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
