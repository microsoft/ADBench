function [varargout]= createFullGradients(varargin)
%CREATEFULLGRADIENTS Create full gradients.
%   [gradients]= createFullGradients(realobjects)
%   Compute the dimension of all realobjects and create
%   gradients, that select EVERY possible direction.
%
%   Since this is the scalar_derivclass, only a single
%   1x1 real object is accepted. This function is supplied
%   for compatibility with the other derivclasses.
%
%   Example call:
%   t = 1; g_t = createFullGradients(t);
%
%   The number of directional derivatives is: 1
%   g_t is ones(1)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2009 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin~= nargout
   error('adimat:runtime:derivclass:scalar:createFullGradients', '%s', ...
         'The number of realobjects and gradients have to be equal.');
end

if nargin ~= 1 || ~isscalar(varargin{1})
   error('adimat:runtime:derivclass:scalar:createFullGradients', '%s', ...
         'Only a single scalar input argument is accepted.');
end

varargout{1} = 1;

% vim:sts=3:

