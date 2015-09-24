% function w = adimat_restore_index(v, ind1, ind2, ...)
%
% Restore array v to the original size and shape w that it had before
% the index delete operation v(ind1,ind2,...) = [] was executed.
%
% see also adimat_push, adimat_push_index
%
% Copyright (C) 2014 Johannes Willkomm <johannes@johannes-willkomm.de>
%
% This file is part of the ADiMat runtime environment
%
function w = adimat_restore_index(v, varargin)
  whichDim = 1;
  for k=1:length(varargin)
    if ~(ischar(varargin{k}) && strcmp(varargin{k}, ':'))
      whichDim = k;
      break
    end
  end
  sz = size(v);
  ind = varargin{whichDim};
  if islogical(ind)
    numDel = sum(ind);
  else
    ind = unique(ind);
    numDel = numel(ind);
  end
  
  if whichDim == 1
    if isrow(v)
      whichDim = 2;
    end
  end
  
  szw = sz;
  szw(whichDim) = szw(whichDim) + numDel;
  allInd = repmat({':'}, length(sz), 1);
  dimLeft = 1:szw(whichDim);
  dimLeft(ind) = [];
  allInd{whichDim} = dimLeft;
  w = v .* 0;
  w(allInd{:}) = v;
end
% $Id: adimat_restore_index.m 4660 2014-09-14 21:07:02Z willkomm $
