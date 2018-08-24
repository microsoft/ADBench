function res = repmat(g, varargin)
%ADDERIV/REPMAT Replicate the derivative object.
%
%  see also adderiv/reshape
% 
% Copyright 2014 Johannes Willkomm
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%

  res = call(@repmat, g, varargin{:});
