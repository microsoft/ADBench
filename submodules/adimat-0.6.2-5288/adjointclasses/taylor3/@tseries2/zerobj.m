function obj = zerobj(obj)
  zv = zeros(size(obj.m_series{1}));
  obj.m_series{1} = zv;
  dv = zerobj(obj.m_series{2});
  obj.m_series(2:obj.m_ord) = {dv};
end
