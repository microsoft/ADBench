% function d_res = adimat_opdiff_sum(d_v1, d_v2, ...)
%
% Copyright 2010-2014 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function v1 = adimat_opdiff_sum(v1, v2, varargin)
  v1 = bsxfun(@plus, v1, v2);
  for k=1:nargin-2
    v1 = bsxfun(@plus, v1, varargin{k});
  end
% $Id: adimat_opdiff_sum.m 4355 2014-05-28 11:10:28Z willkomm $
