function varargout = adimat_diff_kron(varargin)
   varargout{1} = (call(@kron,(varargin{1}),(varargin{4}))+call(@kron,(varargin{2}),(varargin{3})));
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
