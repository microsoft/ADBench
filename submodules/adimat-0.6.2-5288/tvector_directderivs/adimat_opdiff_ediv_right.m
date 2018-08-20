% function r = adimat_opdiff_ediv_right(t_val1, val1, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_ediv_right(t_val1, val1, val2)
  if isscalar(val2)
    r = t_val1 ./ val2;
  else
    [ndd maxOrder nel] = size(t_val1);
    if isscalar(val1)
      nel = prod(size(val2));
      r = t_zeros(val2);
    else
      r = t_val1;
    end
    val2r = reshape(val2, [1 1 nel]);
    for d=1:ndd
      for o=1:maxOrder
        r(d,o,:) = t_val1(d,o,:) ./ val2r;
      end
    end
  end
end
% $Id: adimat_opdiff_ediv_right.m 3226 2012-03-18 12:00:04Z willkomm $
