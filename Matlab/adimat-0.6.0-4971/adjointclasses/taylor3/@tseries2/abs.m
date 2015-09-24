function obj = abs(obj)
  less0 = obj.m_series{1} < 0;
  eq0 = obj.m_series{1} == 0;
  if any(eq0(:))
    warning('adimat:tseries2:abs:argZero', '%s', ...
            'abs is not defined at 0');
  end
  for i=1:obj.m_ord
    obj.m_series{i}(less0) = -obj.m_series{i}(less0);
  end
end
