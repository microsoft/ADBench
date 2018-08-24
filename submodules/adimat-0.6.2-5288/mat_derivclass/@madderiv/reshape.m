function res = reshape(g, varargin)
%MADDERIV/RESHAPE Reshape the derivative object.
%
%  see also madderiv/size, madderiv/numel
% 
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%

  res = call(@reshape, g, varargin{:});
