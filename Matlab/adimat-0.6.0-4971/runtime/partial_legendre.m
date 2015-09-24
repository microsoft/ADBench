function [g_p, p] = partial_legendre(n,x,normalize)
%PARTIAL_LEGENDRE  Compressed local partial derivative of legendre.
%
%   [G_P,P] = PARTIAL_LEGENDRE(N,X,NORMALIZE) evaluates the local partial
%   derivatives of the function
%         P = legendre(N,X,NORMALIZE)
%   with respect to X. Here, N is the degree of the associated Legendre
%   functions and X is the point at which which legendre() and its
%   derivatives are evaluated. More precisely, PARTIAL_LEGENDRE returns the
%   following:
%     (a) P = legendre(N,X,NORMALIZE) 
%     (b) G_P is the local Jacobian of legendre() wrt to X stored in a
%         compressed form as described below.
%   All three normalization schemes specified by the optional parameter
%   NORMALIZE are supported. As in legendre(), the default normalization is
%   given by NORMALIZE = 'unnorm'. See the help of legendre() for more
%   information.
%
%   The local Jacobian of legendre() is a sparse (N+1)L-by-L matrix, where
%   L is the number of elements stored in X. Its particular structure is as
%   follows: Every column consists of at most N+1 nonzero elements. This is
%   exploited by storing the nonzeros of the sparse Jacobian in a matrix of
%   size (N+1)-by-L. This compressed form G_P of the local Jacobian is
%   small and dense. 
%
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

%   Author: H. Martin Buecker, buecker@acm.org
%   Date: 09/03/2013
%
%   Implementation notes:
%   The implementation is based on the following recurrence formula:
%   (1-x*x) (d P^m_n(x) / d x) = - n x P^m_n(x) + (n+m) P^m_{n-1}(x)
% 
%   The current implementation loops over the degree m and then checks for
%   the degree n. However, it may not be a bad idea to handle the case n==0
%   separately at the beginning. This would simplify the coding and
%   increase the readability of the implementation.

% Check on points of non-differentiability

% If we introduce a more rigorous system to cope with points of
% nondifferentiability in the future, we might want to know the indices
% where x=1 or x=-1. We could then use something similar to
%  if any(find( abs(x-1)<tol | abs(x+1)<tol ))
if max(abs(x(:))) >= 1 
    warning('adimat:partial_legendre:evaluatedNondiff',...
           ['The function legendre(N,X) is not differentiable at X=1 and X=-1.\n' ...
            'However, you are evaluating its derivative at one of these points.\n'...
            'Attention: The result of partial_legendre will contain at least one NaN.']);
end

% Set defaut for normalization
if nargin < 3
    normalize = 'unnorm';
end

% Check on inputs by evaluating the original function legendre() which is
% needed anyway.
p = legendre(n,x,normalize);       % P^m_n    (x)
if n > 0
    z = legendre(n-1,x,normalize); % P^m_{n-1}(x)
end

% If x is a vector (either a row or a column vector) of length q,
% then legendre(n,x) returns a two dimensional array of size (n+1) by q.
% However, if x is a three- or higher-dimensional array the behavior is
% different and as follows:
% If n = 0, then it returns whatever x is. For instance,
% >>    size(legendre(0,rand(1,3,2)))
%    ans =  1     3     2
% If n > 0, then it returns an additional dimension just before x like in
% >>    size(legendre(4,rand(1,3,2)))
%    ans =  5     1     3     2

sizex = size(x);
x = x(:).';
py_px = zeros(n+1,length(x),class(x));

% Compute the partial derivative py_px := partial y / partial x as the sum
% of two terms according to the recurrence formula.
% First term:  - n x P^m_n(x)
for m = 0:n
    % Since the dimension of the return value of the function
    % legendre() for a function with degree 0 is different from nonzero
    % degrees, this case needs a special treatment. The above statement
    % to generate the variable p
    %      p = legendre(n,x,normalize)
    % omits the first dimension of the return value for n=0.
    if n == 0
        py_px(m+1,:) = - n*x.*p(:).';
    else
        py_px(m+1,:) = - n*x.*p(m+1,:);
    end
end

% Take care of normalization: We do this by introducing a scaling factor
% SCALE which is used only in the second term of the recurrence formula.
% This scaling factor depends on the degree n which is fixed in this
% routine and also on the value of the order m. Therefore, we introduce a
% vector SCALE of length n+1 that stores the scaling factors for different
% values of the order m = 0, 1, ..., n.
switch normalize
    case 'unnorm'
        % Default: (Unnormalized) associated Legendre functions
        scale = ones(n+1);
    case 'sch'
        % Schmidt seminormalized associated Legendre functions
        scale = ones(n+1);
        % Attention: For the case m = 0, we need a scaling factor of 1.
        % Since the above initialization gives us this in scale(1), the
        % following loop starts at index m = 1.
        for m = 1:n
            scale(m+1) = sqrt((n-m)/(n+m));
        end
    case 'norm'
        % Fully normalized associated Legendre functions
        scale = NaN*ones(n+1);
        for m = 0:n
            scale(m+1) = sqrt(((n+0.5)*(n-m))/((n-0.5)*(n+m)));
        end
    otherwise
        error('Type of normalization in g_legendre is wrong!');
        %error(message('ADiMat:g_legendre:InvalidNormalize', normalize));
end

% Second term: (n+m) P^m_{n-1}(x)
% For the case n = 0, the second term does not exist.
if n > 0
    % Since the degree of the second term is n-1, there is no function with
    % m = n. So, the following loop ends with m = n-1.
    for m = 0:n-1
        % For n = 1, the degree of z is 0. Since the dimension of the
        % return value of the function legendre() for a function with
        % degree 0 is different from nonzero degrees, this case needs a
        % special treatment. The above statement to generate the variable z
        %      z = legendre(n-1,x,normalize)
        % omits the first dimension of the return value for n=1.
        if n == 1
            py_px(m+1,:) = py_px(m+1,:) + scale(m+1)*(n+m).*z(:).';
        else
            py_px(m+1,:) = py_px(m+1,:) + scale(m+1)*(n+m).*z(m+1,:);
        end
    end
end
for m = 0:n
    py_px(m+1,:) = py_px(m+1,:)./(1-x.*x);
end


g_p = py_px;

% The following pice of code makes sure that the derivative g_y has the
% same shape as the result y of the original function.
% Not sure that we will need this property.
%
% Restore original dimensions.
% if original x has more than two dimensions
if length(sizex) > 2 || min(sizex) > 1
    if n == 0
        g_p = reshape(g_p,sizex);
    else
        g_p = reshape(g_p,[n+1 sizex]);
    end
else
    % length(sizex) is either 1 or 2
    % That is, original x is either scalar or vector
    g_p = reshape(g_p,[n+1 max(sizex)]);
end

end
