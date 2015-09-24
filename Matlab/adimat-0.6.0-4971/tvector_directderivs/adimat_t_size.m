% function sz = adimat_d_size(dval)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function sz = adimat_t_size(dval)
  sz = size(dval);
  sz = sz(3:end);
  while length(sz) < 2
    if any(sz == 0)
      sz = [sz 0];
    else
      sz = [sz 1];
    end
  end
% $Id: adimat_t_size.m 3343 2012-07-24 16:15:16Z willkomm $
