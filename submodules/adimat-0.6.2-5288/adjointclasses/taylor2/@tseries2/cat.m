function obj = cat(dim, varargin)
  nempty = cellfun('isempty', varargin);
  ins = varargin(~nempty);
  d_cells = cell(length(ins),1);
  for k=1:length(ins)
    if ~isa(ins{k}, 'tseries2')
      ins{k} = tseries2(ins{k});
    end
    d_cells{k} = ins{k}.m_series;
  end
  obj = ins{1};
  obj.m_series = cellfun(@(varargin) cat(dim, varargin{:}), d_cells{:}, 'UniformOutput', false);
end
