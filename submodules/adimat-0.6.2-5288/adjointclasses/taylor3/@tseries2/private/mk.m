function obj = mk(obj)
  if ~isa(obj, 'tseries2')
    obj = tseries2(obj);
  end
end
