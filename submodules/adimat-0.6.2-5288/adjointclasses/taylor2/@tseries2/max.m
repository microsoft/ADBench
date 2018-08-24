function [obj, mi] = max(obj, right)
  if nargin == 1
    [obj, mi] = max1(obj);
  elseif nargin == 2
    [obj] = max2(obj, right);
  end
end
