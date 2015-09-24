function varargout = adimat_diff_spdiags4(varargin)
[varargout{2}, varargout{4}]=spdiags(varargin{2}); 
varargout{1}= call(@spdiags, varargin{1}, varargout{4});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
