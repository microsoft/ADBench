% function [d_res res] = adimat_opdiff_ediv(d_a, a, d_b, b)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [d_a res] = adimat_opdiff_ediv(d_a, a, d_b, b)
  res = a ./ b;
  d_a = bsxfun(@times, d_a, reshape(1 ./ b, [1 size(b)])) - ...
        bsxfun(@times, d_b, reshape(full(res ./ b), [1 size(res)]));
% $Id: adimat_opdiff_ediv.m 4963 2015-03-03 11:56:24Z willkomm $
