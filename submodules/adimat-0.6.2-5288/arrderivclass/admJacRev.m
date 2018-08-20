% function Jac = admJacRev(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacRev(varargin)
  ndd = get(varargin{1}, 'ndd');
  if nargin == 1
    arg = varargin{1};
    Jac = reshape(get(arg, 'deriv'), [ndd prod(size(arg))]);
  else
    nCompInArgs = 0;
    for i=1:nargin
      nCompInArgs = nCompInArgs + prod(size(varargin{i}));
    end
    Jac = zeros(ndd, nCompInArgs);
    resStart = 0;
    resEnd = 0;
    for argi=1:nargin
      arg = varargin{argi};
      resStart = resEnd + 1;
      resEnd = resEnd + prod(size(arg));
      deriv = get(arg, 'deriv');
      Jac(:, resStart:resEnd) = deriv(:, :);
    end
  end

% $Id: admJacRev.m 4379 2014-05-30 09:52:28Z willkomm $
