% function [g_z, z] = g_logm(g_x, x)
%
% Compute derivative of z = logm(x), matrix logarithm. Also return the
% function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z, z] = g_logm(g_x, x)
  szx = size(x);
  ndd = admGetNDD(g_x);
  if ndd > numel(x)
    [partial z] = partial_logm(x);
    g_z = reshape(partial * g_x(:), size(x));
  else
    base = admJacFor(g_x);
    [partial z] = partial_logm(x, base);
    g_z = g_x;
    for i=1:ndd
      g_z = admSetDD(g_z, i, partial(:,i));
    end
  end
% $Id: g_logm.m 3260 2012-04-03 08:31:34Z willkomm $
