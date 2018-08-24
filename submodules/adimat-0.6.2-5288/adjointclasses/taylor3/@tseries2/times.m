function obj = times(obj, right)
  if isa(obj, 'tseries2')
    oS = obj.m_series;
    if isa(right, 'tseries2')
      rS = right.m_series;
      for k=obj.m_ord:-1:2
        s = timesdv(rS{k}, oS{1});
        for i=2:k-1
          s = plusddes(s, timesdd(oS{i}, rS{k-i+1}));
        end
        oS{k} = plusddes(s, timesdv(oS{k}, rS{1}));
      end
      oS{1} = times(rS{1}, oS{1});
    else
      oS{1} = times(oS{1}, right);
      for k=2:obj.m_ord
        oS{k} = timesdv(oS{k}, right);
      end
    end
  else
    val = obj;
    obj = right;
    oS = obj.m_series;
    oS{1} = times(oS{1}, val);
    for k=2:obj.m_ord
      oS{k} = timesdv(oS{k}, val);
    end
  end
  obj.m_series = oS;
end
