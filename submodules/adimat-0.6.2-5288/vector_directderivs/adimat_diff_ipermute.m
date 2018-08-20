function varargout = adimat_diff_ipermute(varargin)
   varargout{1} = ipermute(varargin{1}, [1 varargin{4}+1]);
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
