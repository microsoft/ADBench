% function res = d_cell(val)
%   Create zero derivative object of cell arrays
%
% see also d_zeros, d_struct
%
% This file is part of the ADiMat runtime environment
%
function res = d_cell(val)
  res = cell(size(val));
  for i=1:numel(val)
    if isfloat(val{i}) || isstruct(val{i}) || iscell(val{i})
      res{i} = d_zeros(val{i});
    end
  end
 
% $Id: d_cell.m 2997 2011-06-21 15:30:11Z willkomm $
