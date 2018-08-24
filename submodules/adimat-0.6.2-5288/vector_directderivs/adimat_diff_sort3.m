function varargout = adimat_diff_sort3(varargin)

       dim = varargin{3};
       [varargout{2}, tmp1]= sort(varargin{2}, varargin{3});
       gP = mk1dperm(tmp1, dim);
       varargout{1} = reshape(varargin{1}(:,gP), size(varargin{1}));
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
