function obj = rdivide(obj, right)
  if ~isa(obj, 'tseries2')
    obj = tseries2(obj);
  end
  oS = obj.m_series;
  if isa(right, 'tseries2')
    rS = right.m_series;
    oS{1} = rdivide(oS{1}, rS{1});
    for k=2:obj.m_ord
      oS{k} = minusdd(oS{k}, timesdv(rS{k}, oS{1}));
      for j=2:k-1
        oS{k} = minusddes(oS{k}, timesdd(oS{j}, rS{k-j+1}));
      end
      oS{k} = rdividedv(oS{k}, rS{1});
    end
  else
    oS{1} = rdivide(oS{1}, right);
    for k=2:obj.m_ord
      oS{k} = rdividedv(oS{k}, right);
    end
  end
  obj.m_series = oS;
end
