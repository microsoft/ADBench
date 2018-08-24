function [varargout]= createHessians(g_dirs, varargin)
%CREATEHESSIANS Create Hessians.
%   [hessians]= createHessians(g_dirs, objects OR gradients)
%   Create a Hessian-matrix for every object OR gradient supplying
%   enough slots for g_dirs number of directional derivatives.
%   Specify either the "normal" object or the gradients, but
%   NEVER both.
%   The hessians will be sparse matrices using the MATLAB 
%   sparse datatype, if applicable.
%   The number of input objects ("normal" objects or gradients)
%   has to be equal to the number of desired Hessians.
%
%   g_dirs is scalar. The Hessian will g_dirs x g_dirs. If g_dirs
%   is a vector than g_dirs(1)==g_dirs(2) has to be true!
%
%   Example call:
%   [h_A, h_b, h_c]= createHessians(7, A, g_b, c);
%
% Copyright 2011      Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if nargin-1~= nargout
   error('The number of input objects and the number of outputs has to be equal.');
end

if g_dirs ~= 1
   error('The number of derivative directions must be 1.');
end

for i=1: nargout
  varargout{i} = zeros(size(varargin{i}));
end

% vim:sts=3:
