function [varargout]= createZeroGradients(g_dirs, varargin)
%CREATEZEROGRADIENTS Create the gradient shells.
%   [gradients]= createEmptyGradients(g_dirs, realobjects)
%   Create for every realobject a gradient object supplying
%   enough slots for g_dirs number of directional derivatives.
%   All gradient objects are zero matrices. 
%   The number of the realobjects has to be equal to the
%   number of gradients.
%
%   Example:
%   [g_A, g_b, g_c]= createZeroGradients(7, A, b, c);
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin-1~= nargout
   error(['The number of realobjects (outputs 2, 3, ...) and gradients  ' ...
          '(inputs 1, 2, ...) have to be equal.']);
end

ndd = g_dirs;
if isempty(g_dirs)
  ndd = get(g_dummy, 'NumberOfDirectionalDerivatives');
end

varargout = cell(nargout, 1);

for i=1: nargout
   varargout{i}= arrdercont(varargin{i}, ndd);
end

% Set the global option, if g_dirs is not empty.
if ~isempty(g_dirs)
  set(g_dummy, 'NumberOfDirectionalDerivatives', g_dirs);
end

% vim:sts=3:
