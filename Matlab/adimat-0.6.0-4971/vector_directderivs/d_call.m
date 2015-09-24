% function [d_z z] = d_call(fun, d_a, a, ...)
%
% Apply function fun to derivative d_a, and also original object a.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function [d_z z] = d_call(fun, d_a, a, varargin)
  z = fun(a, varargin{:});
  szx = size(a);
  d_z = d_zeros(z);
  ndd = size(d_a, 1);
  for i=1:ndd
    dd = fun(reshape(d_a(i,:), szx), varargin{:});
    d_z(i,:) = dd(:).';
  end
end

% $Id: d_call.m 3312 2012-06-19 16:49:07Z willkomm $
