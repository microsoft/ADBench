% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = mldivide(obj, right)
  if isobject(obj)
    warning('why here?')
    res = binopLoop(obj, right, @mldivide);
  else
    if isscalar(obj)
      res = ldivide(obj, right);
    else
      %    fprintf(admLogFile, 'mldivide: (%dm x %dn) \\ (%dm x %dn x %dndd)\n',...
      %            size(obj,1), size(obj,2), size(right,1), size(right,2), right.m_ndd);
      res = arrdercont(right);
      res.m_size = [size(obj, 2) right.m_size(2)];
      res.m_derivs = reshape(obj \ reshape(right.m_derivs, ...
                                           [right.m_size(1) right.m_size(2).*right.m_ndd]),...
                             [res.m_size(1).*res.m_size(2) right.m_ndd]);
    end
  end
end
% $Id: mldivide.m 4346 2014-05-24 18:52:18Z willkomm $
