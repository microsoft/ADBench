function varargout = adimat_diff_sum2(varargin)

        varargout{2} = sum(varargin{2}, varargin{3});
        varargout{1} = sum(varargin{1}, varargin{3} + 2);
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
