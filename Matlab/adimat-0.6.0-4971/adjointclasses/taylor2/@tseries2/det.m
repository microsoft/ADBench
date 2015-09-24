function obj = det(obj)
  if obj.m_ord > 2
    error('adimat:tseries2:det:unsupportedOrder', ...
          ['Taylor coefficients of the function det are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  Ainv = inv(obj.m_series{1});
  Adet = det(obj.m_series{1});
  obj.m_series{1} = Adet;
  obj.m_series{2} = Adet * trace(Ainv * obj.m_series{2});
end
