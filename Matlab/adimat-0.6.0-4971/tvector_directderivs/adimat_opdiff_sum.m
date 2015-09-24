%
% function r = adimat_opdiff_sum(g_v1, g_v2, ...)
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_sum(varargin)
  ndd = size(varargin{1}, 1);
  nargs = nargin;

  scalar = false(1, nargs);
  
  rsz = [];
  for i=1:nargs
    asz = size(varargin{i});
    if prod(asz(3:end)) ~= 1
      if isempty(rsz)
        rsz = asz(3:end);
      end
    else
      scalar(i) = 1;
    end
  end

  if isempty(rsz)
    rsz = [1 1];
  end

  sci = find(scalar);
  
  for i=sci
    varargin{i} = repmat(varargin{i}, [1, 1, rsz]);
  end
  
  r = varargin{1};
  for i=2:nargs
    r = r + varargin{i};
  end

% $Id: adimat_opdiff_sum.m 3224 2012-03-16 15:51:33Z willkomm $
