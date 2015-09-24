% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = set(obj, name, varargin)
  if isa(name, 'char')
    val = varargin{1};
    switch name
     case 'direct'
      obj.m_derivs = reshape(val, [], obj.m_ndd);
     case 'deriv'
      obj.m_derivs = val;
     otherwise
      option(name, val);
    end
  elseif isa(name, 'cell')
    inds = name{1};
    for i=1:length(inds)
      k = inds(i);
      val = varargin{i};
      if ~isequal(size(val), size(obj))
        error('adimat:arrdercont:set:dirder:wrongSize', 'The size of directional derivatives matrix to set is incompatible to number of elements expected. Expected: %s, supplied: %s.', ...
              mat2str(size(obj)), mat2str(size(val)));
      end
      obj.m_derivs(k, :) = val(:);
    end
  end
end
% $Id: set.m 4228 2014-05-17 13:36:32Z willkomm $
