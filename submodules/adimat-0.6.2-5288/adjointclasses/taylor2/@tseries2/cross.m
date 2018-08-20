function obj = cross(obj, right, varargin)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      for k=obj.m_ord:-1:1
        s = cross(obj.m_series{1}, right.m_series{k}, varargin{:});
        for i=2:k
          s = s + cross(obj.m_series{i}, right.m_series{k-i+1}, varargin{:});
        end
        obj.m_series{k} = s;
      end
    else
      for k=1:obj.m_ord
        obj.m_series{k} = cross(obj.m_series{k}, right, varargin{:});
      end
    end
  else
    val = obj;
    obj = right;
    for k=1:obj.m_ord
      obj.m_series{k} = cross(val, obj.m_series{k}, varargin{:});
    end
  end
