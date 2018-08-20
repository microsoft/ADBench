function obj = inv(obj)
  if obj.m_ord > 2
    error('adimat:tseries2:inv:unsupportedOrder', ...
          ['Taylor coefficients of the function inv are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  Ainv = inv(obj.m_series{1});
  obj.m_series{1} = Ainv;
  obj.m_series{2} = - Ainv * obj.m_series{2} * Ainv;
end
