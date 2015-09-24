function obj = zerobj(obj)
  zv = zeros(size(obj.m_series{1}));
  obj.m_series(1:obj.m_ord) = {zv};
end
