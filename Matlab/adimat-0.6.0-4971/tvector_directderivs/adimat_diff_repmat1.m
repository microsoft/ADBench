function varargout = adimat_diff_repmat1(varargin)
   varargout{1} = 0;
   if isstruct(varargin{1})
     varargout{1} = repmat(varargin{1}, varargin{3});
   else
     varargout{1} = repmat(varargin{1}, [1, 1, varargin{3}]);
   end
      ;
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
