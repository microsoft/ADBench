function gz=g_zeros(varargin)
%G_ZEROS Create a gradient object containing all zeros.
%   G_ZEROS(N) creates a gradient object with number of directional derivatives
%              many N-by-N matrices of zeros.
%   G_ZEROS(M,N) or G_ZEROS([M,N]) creates a gradient with n.o.d.d.
%               many M-by-N matrices of zeros.
%   G_ZEROS(M,N,P,...) or G_ZEROS([M N P ...]) creates a gradient with n.o.d.d.
%               many M-by-N-by-P-by-... arrays of zeros.
%
%   If the last argument of g_zeros is a string, then the last
%   argument is discarded. This behaviour is for coping with
%   derivatives of zeros(..., superiorfloat(x,y)), where the
%   call to superiorfloat returns a string.
%
% Copyright 2003-2006 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(varargin{end}, 'char')
   varargin{end}=[];
end

switch nargin
  case 0, gz= adderivsp([], 0, 'zeros');
  case 1, gz= adderivsp([], varargin{1}, 'zeros');
  otherwise gz= adderivsp([], [varargin{:}], 'zeros');
end

