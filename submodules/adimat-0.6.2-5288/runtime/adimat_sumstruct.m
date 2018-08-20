% function res = adimat_sumstruct(a, b)
%   This computes the sum of structs a and b.
%
% see also admDiffRev, adimat_adjsum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
function res = adimat_sumstruct(a, b)
  res = repmat(struct, size(a));
  %  FN = union(fieldnames(a), fieldnames(b));
  FN = fieldnames(a);
  for i=1:length(FN)
    fname = FN{i};
    for i=1:numel(a)
      if ~isfield(a, fname) || ~isfield(b, fname)
        error('field does not exist');
%      elseif prod(size(a(i).(fname))) == 0 || prod(size(b(i).(fname))) == 0
%        error('field is empty');
      elseif prod(size(a(i).(fname))) == 0
        res(i).(fname) = b(i).(fname);
      elseif prod(size(b(i).(fname))) == 0
        res(i).(fname) = a(i).(fname);
      else
        res(i).(fname) = adimat_adjsum(a(i).(fname), b(i).(fname));
      end
    end
  end
  
% $Id: adimat_sumstruct.m 3111 2011-11-04 16:51:24Z willkomm $
