function res = cmpop(obj, right, handle)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      res = handle(obj.m_series{1}, right.m_series{1});
    else
      res = handle(obj.m_series{1}, right);
    end
  else
    res = handle(obj, right.m_series{1});
  end
end
