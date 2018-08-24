% function adj = a_horzcat(adj, v1, v2, ..., vi)
%
% compute adjoint of horzcat(v1, v2, ..., vi, ..., vn) w.r.t. vi.
%
% see also a_vertcat, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2013 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University, TU Darmstadt
function adj = a_horzcat(adj, varargin)
  offsx = 0;
  for i=1:nargin-2
    offsx = offsx + size(varargin{i}, 2);
  end
  sze = size(varargin{end});
  if length(size(adj)) < 3
    adj = adj(:, offsx+1:offsx + sze(2));
  else
    adj = adj(:, offsx+1:offsx + sze(2), :);
  end
  adj = reshape(adj, sze);
% $Id: a_horzcat.m 3874 2013-09-24 13:15:15Z willkomm $
