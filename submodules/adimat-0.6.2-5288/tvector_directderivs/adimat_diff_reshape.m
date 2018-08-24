function varargout = adimat_diff_reshape(varargin)
    varargout{2} = reshape(varargin{2}, varargin{3:end});
    [ndd, maxorder, ~] = size(varargin{1});
    varargout{1} = reshape(varargin{1}, [ndd, maxorder, [varargin{3:end}]]);
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
