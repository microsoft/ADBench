function obj = calln(handle, varargin)
  obj = varargin{1};
  nparm = nargin-1;
  tmpc = cell(nparm, 1);
  for k=1:nargin-1
    tmpc{k} = varargin{k}.m_series{1};
  end
  obj.m_series{1} = handle(tmpc{:});
  for i=2:obj.m_ord
    tmpc = cell(nparm, 1);
    for k=1:nargin-1
      tmpc{k} = varargin{k}.m_series{i};
    end
    obj.m_series{i} = calln(handle, tmpc{:});
  end
end
