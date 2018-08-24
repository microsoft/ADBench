% function r = adimat_adjsum(a, b)
%   This computes the sum of to adjoints. This is needed as long as
%   there is no plsu operator for structs, to handle recursive
%   structs, adimat_sumstruct.
%
% see also admDiffRev, adimat_sumstruct, adimat_sumcell
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
function adj = adimat_adjsum(a, b)
  if isstruct(a)
    adj = adimat_sumstruct(a, b);
  elseif iscell(a)
    adj = cellfun(@adimat_adjsum, a, b, 'uniformoutput', false);
  else
    adj = pluses(a, b);
  end

% $Id: adimat_adjsum.m 4504 2014-06-13 13:36:45Z willkomm $
