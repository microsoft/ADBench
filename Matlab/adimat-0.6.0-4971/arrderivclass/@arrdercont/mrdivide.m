% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = mrdivide(obj, right)
  if isobject(right)
    warning('why here? This probably shows a bug');
    obj = binopLoop(obj, right, @mrdivide);
  else
    if isscalar(right)
      obj = binopFlat(obj, right, @rdivide);
    else
      warning('adimat:mrdivide', '%s', 'optimal version not implemented yet, use \ instead');
      obj = binopLoop(obj, right, @mrdivide);
    end
  end
end
% $Id: mrdivide.m 4823 2014-10-09 20:43:55Z willkomm $
