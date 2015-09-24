% function v = adimat_safediag(M)
%
% Save diag: assuming input is a matrix, return diagonal.
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function v = adimat_safediag(M)
  if isvector(M)
    v = M(1);
  else
    v = diag(M);
  end
end
% $Id: adimat_safediag.m 3917 2013-10-09 15:48:17Z willkomm $
