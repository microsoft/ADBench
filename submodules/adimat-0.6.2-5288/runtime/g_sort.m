% function [g_s s P] = g_sort(g_s, s, varargin)
%
% Compute derivative of sort(s) given derivative of s, g_s.
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [g_s s P] = g_sort(g_s, s, varargin)
  if nargin < 3 || ischar(varargin{1})
    dim = adimat_first_nonsingleton(s);
  else
    dim = varargin{1};
  end
  if dim > ndims(s) && nargout == 2
  else
    [s P] = sort(s, varargin{:});
    if dim <= ndims(s)
      gP = mk1dperm(P, dim);
      g_s = g_s(gP);
    end
  end
end
% $Id: g_sort.m 5034 2015-05-20 20:03:39Z willkomm $
