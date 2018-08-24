function varargout = adimat_diff_polyval1(varargin)
      varargout{2} = polyval(varargin{2}, varargin{4});
   varargout{1} = d_zeros(varargout{2});

   ndd = size(varargin{3}, 1);
   deg = length(varargin{2});
   cDer = polyder(varargin{2});
   
   for i=1:numel(varargin{4})
     cur = varargin{4}(i);
     parC = cur .^ (deg-1:-1:0);
     parX = polyval(cDer, cur);
     for d=1:ndd
       row = parC * reshape(varargin{1}(d,:), deg, 1) + parX * varargin{3}(d,i);
       varargout{1}(d,i) = row;
     end
   end
% [varargout{1}, varargout{2}] = d_polyval(varargin{1}, varargin{2}, varargin{3}, varargin{4})

end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
