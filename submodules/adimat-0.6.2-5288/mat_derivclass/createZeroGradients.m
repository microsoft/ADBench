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
%   Structures in derivative objects: 
%     Structures are no longer stored WITHIN a derivative object.
%     A structure now stores derivative objects in its fields. 
%     Creating a derivative of a structure is simple though. 
%     Assume a s=struct('foo', eye(5), 'bar', 1:4);
%     Creating the derivative structure g_s is done in two steps:
%
%     1. Create the derivative objects for the structure components:
%
%     [g1, g2]= createZeroGradients(ndd, s.foo, s.bar);
%     where ndd is the number of directional derivatives to allocate.
%
%     2. Build g_s by:
%
%     g_s= struct('foo', g1, 'bar', g2);
%
%     In future version of ADiMat this may be automated again, if 
%     recommended by users.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if nargin-1~= nargout
   error('The numbers of realobjects and gradients have to be equal.');
end

for i=1: nargout
   if isstruct(varargin{i})
      error('Behaviour for structs in derivative objects has changed. Try "help createZeroGradients" for more.');
%      res= deepcopy(varargin{i});
%      varargout{i}= madderiv(g_dirs, res, 'object');
   else
      varargout{i}= madderiv(g_dirs, size(varargin{i}), 'zeros');
   end
end

% Set the global option.
set(varargout{1}, 'NumberOfDirectionalDerivatives', g_dirs);

% vim:sts=3:

