% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = cmpop(obj, right, handle)
  if isa(obj, 'arrdercont')
    if isa(right, 'arrdercont')
      res = handle(admGetDD(obj, 1), admGetDD(right, 1));
    else
      res = handle(admGetDD(obj, 1), right);
    end
  else
    res = handle(obj, admGetDD(right, 1));
  end
end
% $Id: cmpop.m 3862 2013-09-19 10:50:56Z willkomm $
