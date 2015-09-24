function obj = mtimes(obj, right)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      for k=obj.m_ord:-1:1
        coeffs = cellfun(@mtimes, obj.m_series(1:k), right.m_series(k:-1:1), 'UniformOutput', false);
        coeffsS = coeffs{1};
        for i=2:length(coeffs)
          coeffsS = coeffsS + coeffs{i};
        end
%        hdim = length(size(coeffs{1})) + 1;
%        coeffsT = cat(hdim, coeffs{:});
%        coeffsS = sum(coeffsT, hdim);
        obj.m_series{k} = coeffsS;
%        s = zeros(size(obj.m_series{k}));
%        for i=1:k
%          s = s + obj.m_series{i} * right.m_series{k-i+1}
%        end
%        obj.m_series{k} = s;
      end
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
