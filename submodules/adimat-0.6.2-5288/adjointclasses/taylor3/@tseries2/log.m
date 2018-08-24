function [obj] = log(obj)
  lT = obj.m_series;
  lT{1} = log(obj.m_series{1});
  eq0 = obj.m_series{1} == 0;
  if any(eq0(:))
    warning('adimat:tseries2:log:argZero', '%s', 'log(x) not defined for x==0');
    lT{2}(~eq0) = rdividedv(lT{2}(~eq0), obj.m_series{1}(~eq0));
    lT{2}(eq0) = 0;
  else
    lT{2} = rdividedv(lT{2}, obj.m_series{1});
  end
  for j=2:obj.m_ord-1
    jsum = timesdv(obj.m_series{j+1}, j);
    for i=1:j-1
      jsum = minusddes(jsum, timesdv(timesddes(lT{i+1}, obj.m_series{j-i+1}),i));
    end
    lT{j+1} = jsum;
    lT{j+1}(~eq0) = lT{j+1}(~eq0) ./ (obj.m_series{1}(~eq0) .* j);
    lT{j+1}(eq0) = 0;
  end
  obj.m_series = lT;
end
