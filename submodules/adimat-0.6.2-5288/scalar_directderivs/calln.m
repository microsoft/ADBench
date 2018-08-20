function res= calln(func, varargin)
%CALLN Call func with all arguments are gradients.
%
% calln(@f, g_v1, g_v2,..., g_vn) expects all g_vi to be directional 
% derivatives, violation of this rule results in incorrect results or errors.
%
% Copyright 2008 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

% Ensure, that func is a function handle and not a string.
if ~ isa(func, 'function_handle')
   func= str2fun(func);
end

res= func(varargin{:});

