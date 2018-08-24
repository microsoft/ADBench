function [sobj, cobj] = sincos(obj)
  sT = obj.m_series;
  cT = obj.m_series;
  sT{1} = sin(obj.m_series{1});
  cT{1} = cos(obj.m_series{1});
  sT{2} = times(obj.m_series{2}, cT{1});
  cT{2} = -times(obj.m_series{2}, sT{1});
  for j=2:obj.m_ord-1
    sT{j+1} = times(obj.m_series{j+1}, cT{1});
    cT{j+1} = -times(obj.m_series{j+1}, sT{1});
    for i=1:j-1
      sT{j+1} = plus(sT{j+1}, times(times(cT{i+1}, obj.m_series{j-i+1}), (j-i)/j));
      cT{j+1} = minus(cT{j+1}, times(times(sT{i+1}, obj.m_series{j-i+1}), (j-i)/j));
    end
  end
  for j=1:obj.m_ord-1
    sT{j+1} = zeros(size(sT{j+1}));
    cT{j+1} = zeros(size(cT{j+1}));
    for i=0:j-1
      sT{j+1} = sT{j+1} + ((j-i)/j) .* cT{i+1} .* obj.m_series{j-i+1};
      cT{j+1} = cT{j+1} - ((j-i)/j) .* sT{i+1} .* obj.m_series{j-i+1};
    end
  end
  sobj = obj;
  cobj = obj;
  sobj.m_series = sT;
  cobj.m_series = cT;
end
