function z = eval(obj, h, maxorder)
  if nargin < 3
    maxorder = obj.m_ord-1;
  end
  z = obj.m_series{1} + deval(obj, h, maxorder);
