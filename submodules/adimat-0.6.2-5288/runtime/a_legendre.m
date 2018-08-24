function a_x = a_legendre(a_p, argnr, n, x, normalize)
%A_LEGENDRE  Propagate derivatives of legendre for admDiffRev.
%
%   A_X = A_LEGENDRE(A_P,ARGNR,N,X,NORMALIZE) propagates
%   backward the derivatives of the function
%         P = legendre(N,X,NORMALIZE)
%   from a given A_P to A_X. Here, N is the degree of the associated
%   Legendre functions and X is the point at which the derivatives of
%   legendre() are evaluated. More precisely, A_LEGENDRE returns the
%   product of the transposed local Jacobian of legendre() and the
%   derivatives A_P. The parameter ARGNR indicates the argument number of
%   P = legendre(N,X,NORMALIZE) with respect to which the local Jacobian is
%   computed. That is, since we always compute derivatives wrt the second
%   argument, X, the parameter ARGNR should always be set to the value 2
%   when calling A_LEGENDRE.
%   All three normalization schemes specified by the optional parameter
%   NORMALIZE are supported. As in legendre(), the default normalization is
%   given by NORMALIZE = 'unnorm'. See the help of legendre() for more
%   information.

%   Author: H. Martin Buecker, buecker@acm.org
%   Date: 09/20/2013
%
%   Implementation notes:
%   The local Jacobian of legendre() is a sparse (N+1)L-by-L matrix, where
%   L is the number of elements stored in X. Its particular structure is as
%   follows: Every column consists of at most N+1 nonzero elements. This is
%   exploited by storing the nonzeros of the sparse Jacobian in a matrix of
%   size (N+1)-by-L. This compressed form of the local Jacobian G_P is
%   small and dense. It is used to compute a series of matrix-by-vector
%   products to compute the product of the transposed local Jacobian and
%   the directional adjoint A_P. For each directional derivative coming
%   with A_P, the algorithm computes a transposed matrix-by-vector product.
%   Conceptually, this is a product of the sparse L-by-(N+1)L matrix and a
%   vector of length (N+1)L. The implementation makes use of the compressed
%   (N+1)-by-L form of G_P, which is the local Jacobian matrix and thus the
%   transpose of the matrix with which the matrix-by-vector product is to
%   be carried out. This G_P is multiplied with the i-th directional
%   adjoint A_P(i,:). The following description of that transposed
%   matrix-by-vector product assumes that A_P(i,:) is a vector rather than
%   a multidimensional array: An inner product of each column M of the
%   compressed form and A_P(i,M+1:N+1:end) is computed. However, as
%   described below, X and thus A_P(i,:) could be multidimensional arrays.
%   Therefore, the actual implementation has to work with the general form
%   of indexing A_P(i,:) rather than with something like
%   A_P(i,k1,k2,k3,...).
%
%   To understand the implementation, recall the following information from
%   legendre() and partial_legendre():
%   Let M = 0, 1, ..., N denote the order of the associated Legendre
%   functions of degree N.
%   If X is a vector with L = length(X), then we have for
%   a) the original function: P is an (N+1)-by-L matrix.
%      The P(M+1,i) entry corresponds to the associated Legendre function
%      of degree N and order M evaluated at X(i).
%   b) the derivative: G_P is also an (N+1)-by-L matrix.
%      The G_P(M+1,i) entry corresponds to the derivative of P(M+1,i) with
%      respect to X(i) evaluated at X(i).
%
%   In general, the returned array has one more dimension than X.
%   Each element P(M+1,i,j,k,...) contains the associated Legendre
%   function of degree N and order M evaluated at X(i,j,k,...). The
%   derivatives G_P(M+1,i,j,k,...) correspond to the derivative of
%   P(M+1,i,j,k,...) with respect to X(i,j,k,...) evaluated at
%   X(i,j,k,...).

switch argnr
    case 2
        
        % Set defaut for normalization
        if nargin < 5
            normalize = 'unnorm';
        end
        
        if n == 0
            % For degree n == 0, return zero derivatives.
            a_x = a_zeros(x);
        else
            % For degree n >= 1, return derivatives according
            % to the recurrence relation.
            
            % Precompute the local Jacobian matrix in compressed form.
            [L_p, p] = partial_legendre(n,x,normalize);

            % Multiply with adjoint, and sum contributions
            a_x = call(@sum, call(@bsxfun, @times, L_p, a_p), 1);

            % Give result the correct shape
            a_x = reshape(a_x, size(x));
            
        end% if n == 0
        
    otherwise
        error(['Wrong derivative selection: ' ...
            'The local Jacobian of legendre(N,X) must be computed wrt X.']);
end
end
