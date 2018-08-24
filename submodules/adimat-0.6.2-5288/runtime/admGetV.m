function v = admGetV(carr)
  if length(carr) == 1
    v = carr{1}(:);
  else
    for i=1:length(carr)
      carr{i} = carr{i}(:);
    end
    v = vertcat(carr{:});
  end
end
