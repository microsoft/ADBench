% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function d_z = d_zeros_size(sz)
  ndd = option('ndd');
  
  if isempty(ndd)
    warning('adimat:vector_directderivs:d_zeros', ...
            '%s', 'd_zeros: the global variable ndd is empty')
  end

  d_z = zeros([ndd sz]);

% $Id$
