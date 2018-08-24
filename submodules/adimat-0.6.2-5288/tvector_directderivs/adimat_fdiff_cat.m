function d_r = adimat_fdiff_cat(dim, varargin)
  empty = cellfun('isempty', varargin);
  dargs = varargin(~empty);
  d_r = cat(dim, dargs{:});
end
% $Id: adimat_fdiff_cat.m 3958 2013-10-29 14:27:14Z willkomm $
