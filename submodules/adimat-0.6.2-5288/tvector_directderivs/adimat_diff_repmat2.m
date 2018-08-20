function varargout = adimat_diff_repmat2(varargin)
   varargout{1} = 0;
   if isstruct(varargin{1})
     varargout{1} = repmat(varargin{1}, varargin{3}, varargin{4:end});
   else
     varargout{1} = repmat(varargin{1}, [1, 1, varargin{3}, varargin{4:end}]);
   end
      ;
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
