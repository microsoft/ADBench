function obj = mtimes(obj, right)
  if isscalar(obj) || isscalar(right)
    obj = times(obj, right);
  else
    if isa(obj, 'tseries2')
      if isa(right, 'tseries2')
        for k=obj.m_ord:-1:2
          coeffs = cellfun(@mtimes, obj.m_series(1:k), right.m_series(k:-1:1), 'UniformOutput', false);
          coeffsS = coeffs{1};
          for i=2:length(coeffs)
            coeffsS = plusddes(coeffsS, coeffs{i});
          end
          obj.m_series{k} = coeffsS;
        end
        obj.m_series{1} = mtimes(obj.m_series{1}, right.m_series{1});
      else
        for k=1:obj.m_ord
          obj.m_series{k} = obj.m_series{k} * right;
        end
      end
    else
      val = obj;
      obj = right;
      for k=1:obj.m_ord
        obj.m_series{k} = val * obj.m_series{k};
      end
    end
  end
end
