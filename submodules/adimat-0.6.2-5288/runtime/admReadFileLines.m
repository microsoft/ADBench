function lines = admReadFileLines(fid)
  lines = cell(1, 1);
  i = 1;
  while 1
    l = fgetl(fid);
    if isequal(l, -1), break; end
    lines{i} = l;
    i = i + 1;
  end
  return

% $Id: admReadFileLines.m 2966 2011-06-09 14:36:33Z willkomm $
