function r = admNDerivIndices(nArgs, actIndices)
  r = 1:nArgs;
  d = zeros(1, nArgs);
  d(actIndices) = 1;
  r = r + cumsum(d);

% $Id: admNDerivIndices.m 4578 2014-06-20 21:07:59Z willkomm $
