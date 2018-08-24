% function sz = adimat_d_size(dval)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function sz = adimat_d_size(dval)
  sz = size(dval);
  sz = sz(2:end);
  if length(sz) < 2
    if any(sz == 0)
      sz = [sz 0];
    else
      sz = [sz 1];
    end
  end

% $Id: adimat_d_size.m 2987 2011-06-15 12:51:01Z willkomm $
