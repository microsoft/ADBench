% function obj = conv(a, b, shape)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (c) 2018 Johannes Willkomm
%
function obj = conv(a, b, shape)
  if nargin < 3
    shape = 'full';
  end
  % determining the output size of conv is complete voodoo, just
  % start a trial balloon and reshape in the end
  if isa(a, 'arrdercont')
    obj = a;
    v = b;
    trial = conv(zeros(size(a)), b, shape);
  else
    obj = b;
    v = a;
    trial = conv(a, zeros(size(b)), shape);
  end
  if isscalar(v)
    obj.m_derivs = obj.m_derivs .* v;
  elseif isscalar(obj)
    obj.m_derivs = bsxfun(@times, obj.m_derivs, reshape(v, [1 size(v)]));
  else
    obj.m_derivs = conv2(reshape(obj.m_derivs, obj.m_ndd, []), v(:).');
  end
  % since we have to use conv2(obj, v), i.e. possibly switch the
  % order of a and b, we cannot use shape with conv2
  % so select the appropriate items here manually
  lena = prod(size(a));
  lenb = prod(size(b));
  switch shape
   case 'full'
   case 'same'
    i0 = floor(lenb./2 + 1);
    sel = i0:i0+lena-1;
    obj.m_derivs = obj.m_derivs(:,sel);
   case 'valid'
    leno = max(lena - lenb + 1, 0);
    ld = lena + lenb - 1 - leno;
    i0 = max(1,ceil((ld+1)/2));
    sel = i0:i0+leno-1;
    obj.m_derivs = obj.m_derivs(:,sel);
  end
  % reshape to the size of the test value
  obj = reshape(obj, size(trial));
end
