%CREATEZEROGRADIENTS Create zero gradients of ndd dimensions.
%   [gradients]= createEmptyGradients(ndd, realobjects)
%   Create for every realobject a gradient object supplying
%   enough slots for g_dirs number of directional derivatives.
%   All gradient objects are zero matrices. 
%   The number of the realobjects has to be equal to the
%   number of gradients.
%
%   Example: This class requires hat the first argument be one.
%   [g_A, g_b, g_c]= createZeroGradients(1, A, b, c);
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [varargout]= createZeroGradients(ndd, varargin)

  if ndd ~= 1
    error('adimat:scalar_directderivs:createZeroGradients', ...
          ['In scalar Forward Mode (FM), the number of' ...
           'directional derivatives must be equal to 1.' ...
           ' However, ndd = %d'], ndd);
  end
  
  if nargin-1 ~= nargout
    error('adimat:scalar_directderivs:createZeroGradients', ...
          ['The number of realobjects and gradients have to be ' ...
           'equal. However, there are %d inputs (except first arg ndd)'...
           'and %d outputs'], nargin-1, nargout);
  end

  for i=1:nargout
    varargout{i} = g_zeros(size(varargin{i}));
  end
