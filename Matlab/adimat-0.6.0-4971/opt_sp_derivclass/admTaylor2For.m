% function HDiag = admTaylor2For(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admTaylor2For(varargin)
  nCompInResult = 0;
  for i=1:nargin
    nCompInResult = nCompInResult + prod(size(varargin{i}));
  end
  ndd = sqrt(prod(admGetNDD(varargin{1})));
  Jac = sparse(nCompInResult, ndd);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd;
    resEnd = resEnd + prod(size(arg));
    for i=1:ndd
      spDD = arg{i,i};
      [is js] = find(spDD);
      for k=1:length(is)
        Jac(resStart + sub2ind(size(spDD), is(k), js(k)), i) = spDD(is(k), js(k));
      end
    end
  end

% $Id: admTaylor2For.m 4522 2014-06-13 20:44:39Z willkomm $
