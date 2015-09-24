function arg= cond_sparse(arg)
% ADDERIVSP/PRIVATE/COND_SPARSE -- Convert the matrix to a sparse one, if
%   the number of nonzeros in the matrix is less then 1/3 of the matrix
%   size.
%
% Copyright 2003, 2004 Andre Vehreschild, Inst. f. Scientific Computing
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if ~issparse(arg) && ndims(arg) == 2 && nnz(arg) < numel(arg)./3
  arg = sparse(arg);
end
