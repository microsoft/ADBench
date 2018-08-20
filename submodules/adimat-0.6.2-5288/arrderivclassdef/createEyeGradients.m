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
for c= 1: nargin
   n_dds = n_dds + admTotalNumel(varargin{c});
end

[varargout{1:nargin}] = createSeededGradientsFor(eye(n_dds), varargin{:});

% vim:sts=3:
