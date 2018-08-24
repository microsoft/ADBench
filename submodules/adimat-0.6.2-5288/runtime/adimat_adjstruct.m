% function r = adimat_adjstruct(s, f, v)
%
% This computes the adjoint of s = struct(f, v).
%
% see also admDiffRev, adimat_sumstruct, adimat_sumcell
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011 Johannes Willkomm, Scientific Computing Group
%           TU Darmstadt.
function r = adimat_adjstruct(s, f, v)
  if iscell(v)
    r = reshape({s.(f)}, size(s));
  else
    r = s.(f);
  end
  
% $Id: adimat_adjstruct.m 3114 2011-11-08 18:19:01Z willkomm $
