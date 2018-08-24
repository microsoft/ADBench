function gz=h_zeros(varargin)
%H_ZEROS Create a hessian object containing all zeros.
%   H_ZEROS(N) creates a Hessian object with number of directional derivatives
%              many N-by-N matrices of zeros.
%   H_ZEROS(M,N) or H_ZEROS([M,N]) creates a Hessian with n.o.d.d.
%               many M-by-N matrices of zeros.
%   H_ZEROS(M,N,P,...) or H_ZEROS([M N P ...]) creates a Hessian with n.o.d.d.
%               many M-by-N-by-P-by-... arrays of zeros.
% Copyright 2003, 2004 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

ndd= get(g_dummy, 'NumberOfDirectionalDerivatives');
if length(ndd)==1 
  ndd= [ndd ndd];
elseif ndd(1)==1
  ndd= [ndd(2) ndd(2)];
end

switch nargin
  case 0, gz= adderivsp(ndd, 0, 'zeros');
  case 1, gz= adderivsp(ndd, varargin{1}, 'zeros');
  otherwise gz= adderivsp(ndd, [varargin{:}], 'zeros');
end

