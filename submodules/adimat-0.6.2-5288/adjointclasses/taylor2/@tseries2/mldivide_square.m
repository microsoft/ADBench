function res = mldivide_square(obj, right)
  [m n] = size(obj);
  opts = struct();
  if m ~= n
    opts.RECT = true;
  end
  res = linsolve_square(obj, right, opts);
end