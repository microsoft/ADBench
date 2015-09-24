% function T2 = admHessianFor(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2012,2014 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Hessian = admHessianFor(varargin)
  nCompInResult = admTotalNumel(varargin{:});

  ndd = get(varargin{1}, 'nddraw');

  Hessian = zeros(ndd(1), ndd(2), nCompInResult);

  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    for i=1:ndd(1)
      for j=1:ndd(2)
        data = arg{i,j};
        Hessian(i, j, resStart:resEnd) = data(:);
      end
    end
  end

% $Id: admHessianFor.m 4441 2014-06-05 13:15:15Z willkomm $
