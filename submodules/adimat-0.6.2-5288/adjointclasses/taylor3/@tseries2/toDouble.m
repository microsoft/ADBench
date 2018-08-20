function val = toDouble(obj)
  nsz = [1 size(toDouble(obj.m_series{1}))];
  vals = cellfun(@(x) reshape(toDouble(x), nsz), obj.m_series, 'UniformOutput', false);
  val = cat(1, vals{:});
end
