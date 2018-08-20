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
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin~= nargout
   error('The number of real objects and expected derivative objects have to be equal.');
end

% Compute the number of all directional derivatives used in this run.

if ~all(cellfun('isclass', varargin, 'double'))
   error('createFullGradients can be applied to scalars, vectors, and matrizes only. More precisely, it can be applied only to objects that base on the double datatype.');
end


sza=cellfun('prodofsize', varargin);
n_dds= sum(sza);

% Create the adderiv-objects. Have a look at the help text above for more 
% information what is done here.

c_ndd= 0;
for c= 1: nargout
   cs= size(varargin{c});
   fd= reshape(repmat([1: cs(1)]', 1, cs(2))', 1, sza(c));
   sd= repmat([0: (cs(2)+1): (cs(2)^2-1)]+1, 1, cs(1))+ (fd-1).*cs(2)^2;
   varargout{c}= madderiv(n_dds, sparse(fd, c_ndd*cs(2)+ sd, ...
         ones(1, sza(c)), cs(1), cs(2)*n_dds, max(round(0.35*sza(c)*cs(2)), ...
            round(sza(c)*1.3))), 'direct'); 
   c_ndd= c_ndd+ sza(c);
end

% Set the global option.
set(varargout{1}, 'NumberOfDirectionalDerivatives', n_dds);

% vim:sts=3:

