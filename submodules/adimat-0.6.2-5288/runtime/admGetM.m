function M = admGetM(carr)
  if length(carr) == 1
    M = carr{1}(:);
  else
    for i=1:length(carr)
      carr{i} = carr{i}(:);
    end
    M = horzcat(carr{:});
  end
end
