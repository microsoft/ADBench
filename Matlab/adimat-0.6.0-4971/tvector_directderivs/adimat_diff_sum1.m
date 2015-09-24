function varargout = adimat_diff_sum1(varargin)

        varargout{2} = sum(varargin{2});
        varargout{1} = sum(varargin{1}, adimat_first_nonsingleton(varargin{2}) + 2);
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
