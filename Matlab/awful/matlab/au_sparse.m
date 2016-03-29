function au_sparse(varargin)
% AU_SPARSE  Create sparse matrices with low time/space overhead.
%           This takes the same arguments as sparse(), but insists
%           that the indices are in the correct order for Matlab's
%           internal format (compressed sparse column), see
%           http://www.mathworks.co.uk/help/matlab/math/accessing-sparse-matrices.html
%           That means that in the call
%              au_sparse(i,j,v)
%           we require
%           1. The columns j should be monotonic, i.e. all(diff(j)>= 0)
%           2. The rows i should be monotonic within columns, i.e:
%               all(diff(i(j==k))>0) forall k=1:max(j)

% Mex is in au_sparse.cxx
error('au_sparse: MEX file not found.  Pleae run au_mexall.\n');
