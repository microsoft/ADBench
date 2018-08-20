% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = linsolve(obj, right, varargin)
  if isobject(obj)
    warning('why here? This probably shows a bug');
    obj = binopLoop(obj, right, @linsolve);
  else
    [m n] = size(obj);
    if nargin > 2
      opts = varargin{1};
    else
      opts = struct();
      if m ~= n
        opts.RECT = true;
      end
    end
    if isscalar(obj)
      res = ldivide(obj, right);
    else
      if isfield(opts, 'TRANSA') && opts.TRANSA
        rm = size(obj, 1);
      else
        rm = size(obj, 2);
      end
      res = arrdercont(right);
      res.m_size = [rm right.m_size(2)];
      res.m_derivs = permute(reshape(linsolve(obj, reshape(permute(right.m_derivs, [2,1,3]), ...
                                                   [right.m_size(1) right.m_ndd.*right.m_size(2)]), opts), ...
                                     [rm right.m_ndd right.m_size(2)]),[2,1,3]);
    end
  end
end
% $Id: linsolve.m 4790 2014-10-07 17:12:11Z willkomm $
