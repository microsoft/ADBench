function res= call(func, g, varargin)
%CALL Call func with one derivative and optional parameters.
%
% call(@f, g, varargin) expects g to be a derivative object, violation of this
% rule results in incorrect results.
%
% Copyright 2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  res= func(g, varargin{:});

% $Id: callwo.m 4796 2014-10-08 10:37:06Z willkomm $
