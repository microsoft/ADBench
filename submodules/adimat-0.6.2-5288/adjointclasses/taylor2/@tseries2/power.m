function obj = power(obj, right)
  if ~isa(right, 'tseries2') && mod(right, 1) == 0
    % power of integers
    % computed by squaring method: is slower
    xs = obj;
    xp = tseries2(ones(size(obj)));
    while right >= 1
      if mod(right, 2) == 1
        xp = xp .* xs;
      end
      xs = xs .* xs;
      right = floor(right ./ 2);
    end
    obj = xp;
  else
    obj = exp(right .* log(obj));
  end
end
