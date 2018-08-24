% function [g_z, z] = g_funm(g_x, x)
%
% Compute derivative of z = funm(x), matrix exponential. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z, z] = g_funm(g_x, x, handle, options)
  if nargin < 4
    moreArgs = {};
  else
    moreArgs = {options};
  end
  szx = size(x);
  ndd = admGetNDD(g_x);
  if ndd > numel(x)
    [partial z] = partial_funm(x, handle, eye(numel(x)), moreArgs{:});
    g_z = reshape(partial * g_x(:), szx);
  else
    base = admJacFor(g_x);
    [partial z] = partial_funm(x, handle, base, moreArgs{:});
    g_z = g_x;
    for i=1:ndd
      g_z = admSetDD(g_z, i, partial(:,i));
    end
  end
% $Id: g_funm.m 3304 2012-06-09 10:13:23Z willkomm $
