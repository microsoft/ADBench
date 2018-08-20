% function adj = a_interp2(adj, xs, ys, v, xis, yis, ...)
%   compute adjoint of v in interp2(adj, xs, ys, v, xis, yis, ...)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function res = a_interp2(adj, argno, varargin)
  nargs = length(varargin);
  if ischar(varargin{end})  % method given
    nargs = length(varargin)-1;
    method = varargin{end};
    extrap = nan();
  elseif ischar(varargin{end-1}) % method + extrapval given
    nargs = length(varargin)-2;
    method = varargin{end-1};
    extrap = varargin{end};
  else
    method = 'linear';
    extrap = nan();
  end
  
  if nargs == 2
    % FIXME
    % case
    % ZI = INTERP2(Z, N)
  end

  Z = varargin{1};

  if nargs <= 1
    % case
    % ZI = INTERP2(Z)
    xis = 1:0.5:size(Z,2);
    yis = 1:0.5:size(Z,1);
  else
    xis = varargin{nargs-1};
    yis = varargin{nargs};
  end
  
  if nargs <= 3
    % case
    % ZI = INTERP2(Z,XI,YI)
    xs = 1:size(Z,1);
    ys = 1:size(Z,2);
    argno = argno + 2;
  else
    xs = varargin{1};
    ys = varargin{2};
    Z = varargin{3};
  end
  
  if isvector(xs) && length(xs) == size(Z,2) ...
    && isvector(ys) && length(ys) == size(Z,1)
    [xs ys] = meshgrid(xs, ys);
  end
  
  if isvector(xis) && isvector(yis)
    [xis yis] = meshgrid(xis, yis);
  end
  
  % nargs == 5: main case
  % ZI = INTERP2(X,Y,Z,XI,YI)
  
  partial = partial_interp2(argno, xs, ys, Z, xis, yis, method, extrap);
  adjtp = (adj(:).' * partial).';
  switch argno
    case {1, 2}
     res = reshape(adjtp, size(xs));
    case {3}
     res = reshape(adjtp, size(Z));
   case {4, 5}
     res = reshape(adjtp, size(xis));
  end

% $Id: a_interp2.m 3516 2013-03-26 09:10:31Z willkomm $
