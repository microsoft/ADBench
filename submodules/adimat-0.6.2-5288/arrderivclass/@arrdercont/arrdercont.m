% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = arrdercont(val, ndd, method)
  if nargin < 1
    val = 0;
  end
  if isstruct(val)
    obj = struct('m_ndd', val.m_ndd, 'm_size', val.m_size, 'm_derivs', val.m_derivs);
  elseif isa(val, 'arrdercont')
    obj = struct('m_ndd', val.m_ndd, 'm_size', val.m_size, 'm_derivs', []);
  else
    if nargin < 3
      if nargin < 2
        ndd = option('ndd');
      end
      sz = size(val);
      ders = zeros([ndd sz]);
      obj = struct('m_ndd', ndd, 'm_size', sz, 'm_derivs', ders);
    else
      tval = ndd;
      tndd = val;
      val = tval;
      ndd = tndd;
      if isempty(ndd)
        ndd = option('ndd');
      end
      sz = size(val);
      if strcmp(method, 'empty')
        ders = [];
      else
        ders = zeros([ndd sz]);
      end
      obj = struct('m_ndd', ndd, 'm_size', sz, 'm_derivs', ders);
    end
  end
  obj = class(obj, 'arrdercont');
end
% $Id: arrdercont.m 4499 2014-06-13 12:02:25Z willkomm $
