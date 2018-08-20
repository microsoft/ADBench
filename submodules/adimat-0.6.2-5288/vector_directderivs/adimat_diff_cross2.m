function varargout = adimat_diff_cross2(varargin)

  d_a = varargin{1};
  a = varargin{2};
  d_b = varargin{3};
  b = varargin{4};
  dim = varargin{5};

  varargout{2} = cross(a, b, dim);
  varargout{1} = d_zeros(varargout{2});

  sza = size(a);
  inds1 = cell(1, length(sza));
  for i=1:length(sza)
    inds1{i} = ':';
  end
  inds2 = inds1;
  inds3 = inds1;
  inds1{dim} = 1;
  inds2{dim} = 2;
  inds3{dim} = 3;

  ndd = size(d_a, 1);
  a = repmat(reshape(a, [1 sza]), [ndd ones(1, length(sza))]);  
  b = repmat(reshape(b, [1 sza]), [ndd ones(1, length(sza))]);  

  varargout{1}(:, inds1{:}) = d_a(:, inds2{:}) .* b(:, inds3{:}) + a(:, inds2{:}) .* d_b(:, inds3{:}) ...
                        - (d_a(:, inds3{:}) .* b(:, inds2{:}) + a(:, inds3{:}) .* d_b(:, inds2{:}));
  varargout{1}(:, inds2{:}) = d_a(:, inds3{:}) .* b(:, inds1{:}) + a(:, inds3{:}) .* d_b(:, inds1{:}) ...
                        - (d_a(:, inds1{:}) .* b(:, inds3{:}) + a(:, inds1{:}) .* d_b(:, inds3{:}));
  varargout{1}(:, inds3{:}) = d_a(:, inds1{:}) .* b(:, inds2{:}) + a(:, inds1{:}) .* d_b(:, inds2{:}) ...
                        - (d_a(:, inds2{:}) .* b(:, inds1{:}) + a(:, inds2{:}) .* d_b(:, inds1{:}));
      
end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
