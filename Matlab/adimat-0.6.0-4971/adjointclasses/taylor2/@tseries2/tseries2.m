function obj = tseries2(val,type)
  if nargin < 1
    obj.m_ord = 0;
    obj.m_series = {};
    obj = class(obj, 'tseries2');
  else
  if isa(val, 'struct')
    if val.m_ord > 1 && isstruct(val.m_series{2})
      func = str2func(val.m_series{2}.className);
      val.m_series(2:end) = cellfun(func, val.m_series(2:end), 'uniformoutput', false);
    end
    obj.m_ord = val.m_ord;
    obj.m_series = val.m_series;
    obj = class(obj, 'tseries2');
  elseif isa(val, 'tseries2')
    obj = val;
    switch type
     case 'zeros'
      obj = zerobj(obj);
    end
  else
    options = option('options');
    nord = options.ord+1;
    obj = struct('m_ord', nord, ...
                 'm_series', {cell(nord, 1)});
    obj.m_series{1} = val;
    iv = zeros(size(val));
    obj.m_series(2:nord) = {iv};
    obj = class(obj, 'tseries2');
  end
  end
end
