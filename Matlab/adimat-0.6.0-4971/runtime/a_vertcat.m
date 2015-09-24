% function adj = a_vertcat(adj, v1, v2, ..., vi)
%
% compute adjoint of vertcat(v1, v2, ..., vi, ..., vn) w.r.t. vi.
%
% see also a_horzcat, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function adj = a_vertcat(adj, varargin)
  offsy = 0;
  for i=1:nargin-2
    offsy = offsy + size(varargin{i}, 1);
  end
  adj = reshape(adj(offsy+1:offsy + size(varargin{end}, 1), :), size(varargin{end}));

% $Id: a_vertcat.m 3114 2011-11-08 18:19:01Z willkomm $
