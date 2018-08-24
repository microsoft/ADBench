function varargout = adimat_diff_sort4(varargin)

       dim = varargin{3};
       [varargout{2}, varargout{3}]= sort(varargin{2}, varargin{3});
       gP = mk1dperm(varargout{3}, dim);
       varargout{1} = reshape(varargin{1}(:,gP), size(varargin{1}));
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
