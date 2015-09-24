function obj = sqrt(obj)
  eT = obj.m_series;
  eT{1} = sqrt(obj.m_series{1});
  eT12 = 2 .* eT{1};

  eT{2} = obj.m_series{2} ./ eT12;
  
  for k=3:obj.m_ord
    eT{k} = -eT{k-1} .* eT{2};
    for j=3:k-1
      eT{k} = eT{k} - eT{k-j+1} .* eT{j};
    end
    eT{k} = eT{k} + obj.m_series{k};
    eT{k} = eT{k} ./ eT12;
  end
  obj.m_series = eT;
end
