function [varargout]= createFullGradients(varargin)
%CREATEFULLGRADIENTS Create full gradients.
%   [gradients]= createFullGradients(realobjects)
%   Compute the dimension of all realobjects and create
%   gradients, that select EVERY possible direction.
%
%   Example call:
%   A= eye(5); b= [1,2,3]; c= 42;
%   [g_A, g_b, g_c]= createFullGradients(A, b, c);
%
%   The number of directional derivatives is: 5*5+3*1+1= 29
%   g_A{1}(1,1)=1; everywhere else 0
%   g_A{2}(1,2)=1;     "        "  0
%      ...
%   g_A{5}(1,5)=1;     "        "  0
%   g_A{6}(2,1)=1;     "        "  0
%      ...
%   g_A{25}(5,5)=1;    "        "  0
%   g_b{1:25}=[0,0,0] and g_c{1:25}=0;
%
%   g_A{26:28}= zeros(5);
%   g_b{26}(1)=1; everywhere else 0
%   g_b{27}(2)=1;      "       "  0
%   g_b{28}(3)=1;      "       "  0
%   g_c{26:28}=0;
%
%   g_A{29}=zeros(5); g_b{29}=[0,0,0]; g_c{29}=1;
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin~= nargout
   error('The number of realobjects and gradients have to be equal.');
end

% Compute the number of all directional derivatives used in this run.

n_dds=0;
sza= cell(nargin,1);
for c= 1: nargin
   if isstruct(varargin{c})
      error('Can not create Full-gradient for structures. Use createZeroGradients instead and seed manually.');
   end
sza{c}= size(varargin{c});
   n_dds= n_dds+prod(sza{c});
end

% Create the adderiv-objects. Have look at the help text above for more 
% information what is done here.

c_ndd= 1;
for c= 1: nargout
   res = adderivsp(n_dds, sza{c}, 'zeros'); 
   for i= 1:prod(sza{c})
     res{c_ndd}(i)= 1;
     c_ndd= c_ndd+ 1;
   end
   varargout{c} = res;
end

% Set the global option.
set(varargout{1}, 'NumberOfDirectionalDerivatives', n_dds);

% vim:sts=3:

