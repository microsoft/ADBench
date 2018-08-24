% function Jac = admJacFor(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the vector_directderivs derivative "class".
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacFor(varargin)
  ndd = size(varargin{1}, 1);
  if nargin == 1
    Jac = varargin{1}(:,:).';
  else
    nCompInResult = admGetTotalNumel(varargin{:}) ./ max(ndd, 1);
    Jac = zeros(nCompInResult, ndd);
    if ndd > 0
      resStart = 0;
      resEnd = 0;
      for argi=1:nargin
        arg = varargin{argi};
        resStart = resEnd + 1;
        nel = prod(size(arg)) ./ ndd;
        resEnd = resEnd + nel;
        Jac(resStart:resEnd, :) = reshape(arg, [ndd nel]).';
      end
    end
  end

% $Id: admJacFor.m 4407 2014-06-03 11:21:02Z willkomm $
