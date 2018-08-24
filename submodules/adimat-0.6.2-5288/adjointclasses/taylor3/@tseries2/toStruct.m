function res = toStruct(obj)
  res.m_series = obj.m_series;
  res.m_ord = obj.m_ord;
  if res.m_ord > 1 && isobject(res.m_series{2})
    res.m_series(2:end) = cellfun(@toStruct, res.m_series(2:end), 'uniformoutput', false);
  end
  res.adimat_cname = 'tseries2';
end
