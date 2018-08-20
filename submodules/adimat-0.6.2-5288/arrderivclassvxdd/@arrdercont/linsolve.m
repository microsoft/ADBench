% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = linsolve(obj, right, varargin)
  if isobject(obj)
    warning('why here?')
    res = binopLoop(obj, right, @mldivide);
  else
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
      res.m_derivs = reshape(linsolve(obj, reshape(right.m_derivs, ...
                                                   [right.m_size(1) right.m_size(2).*right.m_ndd]), opts),...
                             [res.m_size(1).*res.m_size(2) right.m_ndd]);
    end
  end
end
% $Id: linsolve.m 4804 2014-10-08 13:22:04Z willkomm $
