% function R = mk1DPerm(P, dim)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function R = mk1dperm(P, dim)
  sz = size(P);
  inds = cell(ndims(P), 1);
  for k=1:ndims(P)
    if k == dim
      inds{k} = P;
    else
      inds{k} = repmat(reshape(1:sz(k), [ones(1, k-1) sz(k) ones(1, ndims(P)-k)]),...
                       [sz(1:k-1) 1 sz(k+1:end)]);
    end
  end
  R = sub2ind(sz, inds{:});
end
% $Id: mk1dperm.m 4980 2015-05-11 05:58:14Z willkomm $
