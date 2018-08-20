function varargout = adimat_diff_vertcat(varargin)
   varargout{2} = vertcat(varargin{2:2:end});
   if iscell(varargin{2}) || isstruct(varargin{2})
      varargout{1} = vertcat(varargin{1:2:end});
   else
      varargout{1} = cat(2, varargin{1:2:end});
   end

end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
