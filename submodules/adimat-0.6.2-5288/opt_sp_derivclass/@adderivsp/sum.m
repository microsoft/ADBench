function res=sum(g, varargin)
%ADDERIV/SUM Compute sum on the derivative object.
%
%  see also sum, createFullGradients, g_zeros
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
  
  res = call(@sum, g, varargin{:});
