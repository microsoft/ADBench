function res=sum(g, varargin)
%ADDERIV/SUM Compute sum on the derivative object.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
% This file is part of the ADiMat runtime environment
%
  res = call(@sum, g, varargin{:});
