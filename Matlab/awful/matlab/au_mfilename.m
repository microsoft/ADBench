function mfile = au_mfilename(offset)
% AU_MFILENAME  Return filename of caller, or "[base workspace]"
%               OFFSET = -1 is caller's caller...

if 0
    %% Test code -- use CTRL-ENTER to run
    a = au_mfilename;
    au_test_regexp(a, '[base workspace]');
    au_mfilename_test;

end

if nargin == 0
    offset = 0;
end

offset = 2-offset;
s = dbstack;
if length(s) < offset
  mfile = '[base workspace]';
else
  mfile = s(offset).name;
end
