function disp(obj)
  fprintf('Taylor series of order %d of size %s\n', obj.m_ord, mat2str(size(obj)));
  for i=1:obj.m_ord
    fprintf('Coefficients of order %d:\n', i-1);
    disp(obj.m_series{i});
  end
end
