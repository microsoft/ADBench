% function Jac = admJacRev(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacRev(varargin)
  Jac = admJacFor(varargin{:}) .';

% $Id: admJacRev.m 4458 2014-06-10 06:55:37Z willkomm $
