function [varargout]= createEyeGradients(varargin)
%CREATEEYEGRADIENTS Create gradients, with only the diagonals set to one
%   [gradients]= createEyeGradients(realobjects)
%   Compute the minimal dimension of all realobjects and create
%   gradients, that select diagonal directions only.
%
%   Example:
%   A= eye(5,3); b= [1,2,3]; c= 42;
%   [g_A, g_b, g_c]= createEyeGradients(A, b, c);
%
%   The number of directional derivatives is: 3+1+1= 5
%   g_A{1}(1,1)=1; everywhere else 0
%   g_A{2}(2,2)=1;     "        "  0
%   g_A{3}(3,3)=1:     "        "  0
%   g_b{1:3}= [0,0,0]; g_c{1:3}= 0;
%
%   g_A{4}= zeros(5,3);
%   g_b{4}(1)=1; everywhere else 0
%   g_c{4}=0;
%
%   g_A{5}=zeros(5,3); g_b{5}=[0,0,0];
%   g_c{5}=1;
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin~= nargout
   error('The number of realobjects and gradients have to be equal.');
end

n_dds=0;
sza= cell(nargin,1);
for c= 1: nargin
   if isstruct(varargin{c})
      error('Can not create Eye-gradient for structures. Use createZeroGradients instead and seed manually.');
   end
   sza{c}= size(varargin{c});
   n_dds= n_dds+prod(sza{c});
end

c_ndd= 1;
for c= 1: nargout
   varargout{c}= adderivsp(n_dds, sza{c}, 'zeros');
   for i= 1: prod(sza{c})
      varargout{c}{c_ndd}(i)= 1;
      c_ndd= c_ndd+ 1;
   end
end

set(varargout{1}, 'NumberOfDirectionalDerivatives', n_dds);

% vim:sts=3:
