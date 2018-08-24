% function [partial z] = partial_interp2(xs, ys, vs, xis, yis, ...)
%   compute partial interp2(xs, ys, vs, xis, yis, ...) w.r.t. to vs
%
% See also:
%  http://en.wikipedia.org/wiki/Bilinear_interpolation
%  http://en.wikipedia.org/wiki/Bicubic_interpolation
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp2(argno, xs, ys, vs, xis, yis, varargin)
  
  switch argno,
    
   case {1, 2}
    % no idea
    warning('unsupported: adjoint of arg 1 or 2');
    partial = zeros([numel(xis), numel(xs)]);
   
   case 3
    partial = zeros([numel(xis), numel(vs)]);
    d_vs = zeros(size(vs));
    for i=1:numel(vs)
      d_vs(i) = 1;
      t = interp2(xs, ys, d_vs, xis, yis, varargin{:});
      partial(:,i) = t(:);
      d_vs(i) = 0;
    end
   
   case 4
    % FIXME
    warning('unsupported: adjoint of interp2 w.r.t. arg 4');
    partial = zeros([numel(xis), numel(xis)]);
    
    %    for i=1:size(vs,1)
     % partial = partial_interp1_3(xs, vs, xis, varargin{:});
     %    end
    
   case 5
    % FIXME
    warning('unsupported: adjoint of interp2 w.r.t. arg 5');
    partial = zeros([numel(xis), numel(yis)]);
    % partial = partial_interp1_3(ys, vs, yis, varargin{:});
    
  end
  
  if nargout > 1
    z = interp2(xs, ys, vs, xis, yis, varargin{:});
  end
% $Id: partial_interp2.m 3516 2013-03-26 09:10:31Z willkomm $
