function [sobj, cobj] = sinhcosh(obj)
  sT = obj.m_series;
  cT = obj.m_series;
  sT{1} = sinh(obj.m_series{1});
  cT{1} = cosh(obj.m_series{1});
  for j=1:obj.m_ord-1
    sT{j+1} = zeros(size(sT{j+1}));
    cT{j+1} = zeros(size(cT{j+1}));
    for i=0:j-1
      sT{j+1} = sT{j+1} + ((j-i)/j) .* cT{i+1} .* obj.m_series{j-i+1};
      cT{j+1} = cT{j+1} + ((j-i)/j) .* sT{i+1} .* obj.m_series{j-i+1};
    end
  end
  sobj = obj;
  cobj = obj;
  sobj.m_series = sT;
  cobj.m_series = cT;
end
