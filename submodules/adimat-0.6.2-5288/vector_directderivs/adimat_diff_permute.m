function varargout = adimat_diff_permute(varargin)
   varargout{1} = permute(varargin{1}, [1 varargin{4}+1]);
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
