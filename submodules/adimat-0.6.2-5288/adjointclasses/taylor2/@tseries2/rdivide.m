function obj = rdivide(obj, right)
  if ~isa(obj, 'tseries2')
    obj = tseries2(obj);
  end
  if isa(right, 'tseries2')
    obj.m_series{1} = obj.m_series{1} ./ right.m_series{1};
    for k=2:obj.m_ord
      for j=2:k
        obj.m_series{k} = obj.m_series{k} - obj.m_series{j-1} .* right.m_series{k-j+2} ;
      end
      obj.m_series{k} = obj.m_series{k} ./ right.m_series{1};
    end
  else
    for k=1:obj.m_ord
      obj.m_series{k} = obj.m_series{k} ./ right;
    end
  end
end
