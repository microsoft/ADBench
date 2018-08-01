function out = au_fscan_regexp(fid, delim_re)
% AU_FSCAN_REGEXP  File scan line by line splitting on regexp
%          out = au_fscan_regexp(fid, delim_re)
%          Return cell array of cell arrays of strings

% awf, jun14

f = fopen(fid, 'rt');
if f<0
    error('awful:fscan', 'Could not open file [%s]', fid)
end
out = {};
while ~feof(f)
  l = fgetl(f);
  if isequal(l, -1)
    break
  end
  strs = regexp(l, delim_re, 'split');
  
  if isempty(strs)
    fprintf(2, 'Mismatched line [%s]\n', l);
    break
  end
  out{end+1} = strs;
end
fclose(f);
