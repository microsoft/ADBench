% function [partial z exitflag output] = partial_funm(x, handle, base, options)
%
% [partial z] = partial_funm(x, handle, base) computes partial
% derivative of z = funm(x, handle). Also returns the function result
% z.
%
% [partial z] = partial_funm(x, handle, base, options) compute partial
% derivative of z = funm(x, handle, options).
%
% Only implemented for the standard cases handle = @sin, @cos, @log,
% @exp, @sinh, @cosh, not for user function handles.
%
% see also g_funm, a_funm
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z exitflag output] = partial_funm(x, handle, base, options)
  if nargin < 3
    base = eye(numel(x));
  end
  if nargin < 4
    funm_args = {handle};
  else
    funm_args = {handle, options};
  end

  nMoreOut = nargout('funm') - 1;
  [partial z moreOut{1:nMoreOut}] = matdiff(x, @(x) funm(x, funm_args{:}), base);
  
  if nMoreOut > 0
    exitflag = moreOut{1};
    if exitflag
      funName = func2str(handle);
      warning('adimat:partial_funm', ...
              'funm of function %s returned an error', ...
              funName);
    end
  end

% $Id: partial_funm.m 4688 2014-09-18 10:01:13Z willkomm $
