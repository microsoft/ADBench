function [varargout]= callm(func, varargin)
%CALLM Call func with all arguments and results begin direct. deriv.
%
% [g_o1, g_o2,... g_om]= callm(@f, g_v1, g_v2,..., g_vn) expects all g_vi
% to be directional derivatives. Violation of this convention may results in
% incorrect results or errors.
%
% Copyright 2008 Andre Vehreschild, Institute for Scientific Computing
%                RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

   % In addressing the varargout the actual number of results has to be
   % used in the index to enforce that func() initializes all of them 
   % upon return.
   [varargout{1:nargout}]= func(varargin{:});

