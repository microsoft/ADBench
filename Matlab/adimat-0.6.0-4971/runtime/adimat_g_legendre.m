function [g_p, p] = adimat_diff_legendre_for(~, n, g_x, x, normalize)
%ADIMAT_DIFF_LEGENDRE_FOR  Propagate derivatives of legendre for admDiffFor.
%
%   [G_P,P] = ADIMAT_DIFF_LEGENDRE(D_N,N,G_X,X,NORMALIZE) propagates
%   forward the derivatives of the function
%         P = legendre(N,X,NORMALIZE)
%   from G_X to G_P. Here, N is the degree of the associated Legendre
%   functions and X is the point at which legendre() and its derivatives
%   are evaluated. More precisely, ADIMAT_DIFF_LEGENDRE returns the
%   following: 
%     (a) P = legendre(N,X,NORMALIZE) 
%     (b) G_P is the product of the local Jacobian of legendre() and the
%         directional derivatives G_X. 
%   All three normalization schemes specified by the optional parameter
%   NORMALIZE are supported. As in legendre(), the default normalization is
%   given by NORMALIZE = 'unnorm'. See the help of legendre() for more
%   information.

%   Author: H. Martin Buecker, buecker@acm.org
%   Date: 09/27/2013
%
%   Implementation notes:
%   The local Jacobian of legendre() is a sparse (N+1)L-by-L matrix, where
%   L is the number of elements stored in X. Its particular structure is as
%   follows: Every column consists of at most N+1 nonzero elements. This is
%   exploited by storing the nonzeros of the sparse Jacobian in a matrix of
%   size (N+1)-by-L. This compressed form of the local Jacobian is small
%   and dense. It is used to compute a series of matrix-by-vector products
%   to compute the product of the local Jacobian and the directional
%   derivatives G_X. For each directional derivative coming with G_X, the
%   algorithm computes a matrix-by-vector product. Conceptually, this is a
%   product of the sparse (N+1)L-by-L matrix and a vector of length L. In
%   the implementation, the compressed (N+1)-by-L form of that matrix is
%   multiplied with the i-th directional derivative G_X{i}(:). The following
%   description of that matrix-by-vector product assumes that G_X{i}(:) is a
%   vector rather than a multidimensional array:
%   Each column k of the compressed form is multiplied by G_X{i}(k), the
%   k-th entry of the vector G_X{i}(:). However, as described below, X and
%   thus G_X{i}(:) could be multidimensional arrays. Therefore, the actual
%   implementation has to work with the general form of indexing G_X{i}(:)
%   rather than with something like G_X{i}(k1,k2,k3,...).
%
%   To understand the implementation, recall the following information from
%   legendre() and partial_legendre():
%   Let M = 0, 1, ..., N denote the order of the associated Legendre
%   functions of degree N.
%   If X is a vector with L = length(X), then we have for
%   a) the original function: P is an (N+1)-by-L matrix.
%      The P(M+1,i) entry corresponds to the associated Legendre function
%      of degree N and order M evaluated at X(i).
%   b) the local derivative: L_P is also an (N+1)-by-L matrix.
%      The L_P(M+1,i) entry corresponds to the derivative of P(M+1,i) with
%      respect to X(i) evaluated at X(i).
%
%   In general, the returned array has one more dimension than X.
%   Each element P(M+1,i,j,k,...) contains the associated Legendre
%   function of degree N and order M evaluated at X(i,j,k,...). The
%   derivatives L_P(M+1,i,j,k,...) correspond to the derivative of
%   P(M+1,i,j,k,...) with respect to X(i,j,k,...) evaluated at
%   X(i,j,k,...).

% Set defaut for normalization
if nargin < 5
    normalize = 'unnorm';
end

if n == 0
    % For degree n == 0, return original function and zero derivatives.
    p = legendre(n,x,normalize);
    g_p = g_zeros(size(p));
else
    % For degree n >= 1, return original function and derivatives according
    % to the recurrence relation.
    
    % Precompute the partials and the original function.
    [L_p, p] = partial_legendre(n,x,normalize);
    
    % Let 
    q = length(x(:)); 
    % denote the number of elements contained in x. (In the above comment,
    % q is replaced by L. However, we avoid the character "l" in
    % programming because it is easily confused with the integer "1".) 
    % The function partial_legendre() returns the local partial Jacobian of
    % size (n+1)q-by-q in a compact form. That is, the structure of the
    % local partial Jacobian is exploited and the result is the compact
    % form L_p which is an (n+1)-by-q matrix conceptually. However, from a 
    % data structure point of view, the local partial derivative L_p is an
    % (n+1)-by-q matrix only for the degree n = 0 which is irrelevant
    % in this if case. For the relevant if case n >= 1, the local partial
    % derivative L_p is not an (n+1)-by-q matrix  but rather a matrix of
    % the form L_p(m+1,i,j,k,...). Therefore, the following implementation
    % will always work with L_p(m+1,:) rather than with L_p(m+1,i,j,k,...).
    
    % Initialize the derivative result.
    g_p = g_zeros(size(p));
    
    % Get number of directional derivatives.
    ndd = get(g_dummy,'NumberOfDirectionalDerivatives');
    
    % Initialize temporary variable.
    tmp_g_p = zeros(n+1,q);
    % Handle each derivative direction i separately in the following loop.
    for i = 1:ndd
        % Multiply the local Jacobian of legendre() with the i-th
        % directional derivative g_x{i}(:). However, exploit the structure
        % of the sparse Jacobian which is represented by the small and
        % dense matrix L_p here.
        
        % g_x{i}(:) is the i-th directional derivative of x wrt the
        % independent variables reshaped as a long vector.

        for m = 0:n
            tmp_g_p(m+1,:) = L_p(m+1,:) .* g_x{i}(:).';
        end
        g_p{i}(:) = tmp_g_p(:);
    end% for i = 1:ndd
end% if n == 0

end

