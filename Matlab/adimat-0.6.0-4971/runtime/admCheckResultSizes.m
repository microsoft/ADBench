% function res = admCheckResultSizes(values, derivatives)
%
% Check that derivative outputs and their corresponding values have
% the same size.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                 TU Darmstadt
function res = admCheckResultSizes(values, derivatives)
  res = true;
  for i=1:length(values)
    d_resi = derivatives{i};
    resi = values{i};
    dsz = size(d_resi);
    sz = size(resi);
    if ~isequal(dsz, sz)
      res = false;
      warning('adimat:wrongResultSize', ...
              'The size of the argument %d is %s, but it should be %s', ...
              i, mat2str(dsz), mat2str(sz));
    end
  end
end
% $Id: admCheckResultSizes.m 4833 2014-10-13 07:11:09Z willkomm $
