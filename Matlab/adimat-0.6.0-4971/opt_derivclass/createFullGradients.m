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
% see also createZeroGradients, createSeededGradientsRev,
% createSeededGradientsRev, g_zeros
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  if nargin~= nargout
    error('The number of realobjects and gradients have to be equal.');
  end
  if nargin == 0
    error('There must be at least one argument.');
  end
  
  % Compute the number of all directional derivatives used in this run.

  ndd = admTotalNumel(varargin);
  
  % Create the adderiv-objects. Have look at the help text above for more 
  % information what is done here.
  
  varargout = cell(nargout, 1);
  
  offs = 0;
  for c= 1: nargout
    arg = varargin{c};
    if ~isnumeric(arg)
      error('adimat:nonNumericDiffArg', ...
            'All inputs must be numeric, but arg %d has class %s\n', ...
            k, class(arg));
    end
    sz = size(arg);
    darg = adderiv(ndd, sz, 'zeros');
    ders = get(darg, 'deriv');
    nel = prod(sz);
    for i = 1:nel
      ders{offs + i}(i) = 1;
    end
    offs = offs + nel;
    darg = set(darg, 'deriv', ders);
    varargout{c} = darg;
  end
  
  % Set the global option.
  set(varargout{1}, 'NumberOfDirectionalDerivatives', ndd);
  
% $Id: createFullGradients.m 4537 2014-06-14 21:02:30Z willkomm $
