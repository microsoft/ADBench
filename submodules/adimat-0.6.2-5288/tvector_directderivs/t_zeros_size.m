% function t_z = t_zeros_size(sz)
%
% Return zero taylor coefficients of size sz.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function t_z = t_zeros_size(sz)
  ndd = option('ndd');
  nord = option('order');

  t_z = zeros([ndd nord sz]);

% $Id: t_zeros_size.m 3240 2012-03-20 22:15:10Z willkomm $
