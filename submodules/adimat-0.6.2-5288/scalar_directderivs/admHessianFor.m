% function Jac = admJacFor(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admHessianFor(varargin)
  Jac = admJacFor(varargin{:});

%Id%
