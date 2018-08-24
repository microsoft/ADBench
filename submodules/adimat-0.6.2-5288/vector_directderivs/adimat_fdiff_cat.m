function d_r = adimat_fdiff_cat(dim, varargin)
  empty = cellfun('isempty', varargin);
  dargs = varargin(~empty);
  d_r = cat(dim, dargs{:});
end
% $Id: adimat_fdiff_cat.m 3884 2013-09-26 12:00:53Z willkomm $
