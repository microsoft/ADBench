function r = admNDerivIndices2(nArgs, actIndices)
  r = 1:nArgs;
  d = zeros(1, nArgs);
  d(actIndices) = 3;
  r = r + cumsum(d);

% $Id: admNDerivIndices2.m 4576 2014-06-20 21:07:08Z willkomm $
