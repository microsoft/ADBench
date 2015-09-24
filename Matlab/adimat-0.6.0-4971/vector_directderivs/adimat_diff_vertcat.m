function varargout = adimat_diff_vertcat(varargin)
   varargout{2} = vertcat(varargin{2:2:end});
   if iscell(varargin{2}) || isstruct(varargin{2})
      varargout{1} = vertcat(varargin{1:2:end});
   else
      varargout{1} = cat(2, varargin{1:2:end});
   end

end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
