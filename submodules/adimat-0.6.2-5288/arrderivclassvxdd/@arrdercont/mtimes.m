% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = mtimes(obj, right)
  if isscalar(obj) || isscalar(right)
    res = times(obj, right);
  else
    if isobject(obj)
      if isobject(right)
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn x %dndd)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2), right.m_ndd);
        res = arrdercont(obj);
        res.m_size = [obj.m_size(1) right.m_size(2)];
        dd1 = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
        dd2 = reshape(right.m_derivs, [right.m_size obj.m_ndd]);
        res.m_derivs = admMatMultV3TT(dd1, dd2);
      else
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2));
        res = arrdercont(obj);
        res.m_size = [obj.m_size(1) size(right, 2)];
        dd1 = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
        res.m_derivs = admMatMultV3TM(dd1, right);
      end
    else
%      fprintf(admLogFile, 'mtimes: (%dm x %dn) * (%dm x %dn x %dndd)\n',...
%              size(obj,1), size(obj,2), size(right,1), size(right,2), right.m_ndd);
      res = arrdercont(right);
      res.m_size = [size(obj, 1) right.m_size(2)];
      dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
      res.m_derivs = admMatMultV3MT(obj, dd2);
    end
    res.m_derivs = reshape(res.m_derivs, [prod(res.m_size) res.m_ndd]);
  end
end
% $Id: mtimes.m 4477 2014-06-12 08:31:45Z willkomm $
