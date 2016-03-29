function au_system(varargin)
% AU_SYSTEM   Issue system command with matlab-separated arguments
%             The matlab system command requires you to generate a command
%             string rather than passing separate arguments
%             For example,
%             system('dir', '/w', '*.m') fails oddly
%             au_system('dir', '/w', '*.m')  -> !dir /w "*.m"
%             
%             Specifically, it encases arguments in double quotes
%             if they contain spaces or special characters, and
%             generates a string that is passed to the OS command.

if nargin == 0
    %% Test
    if ispc
        au_system dir /w *.m
        au_system('dir', '/w', 'c:\program files*')
        au_system('dir', '/w', '"c:\program files*"')
    else
        error('not tested on other os''s');
    end
    return
end

cmd ='';
for k=1:length(varargin)
    s = varargin{k};
    noquote_needed_re = '^[a-zA-Z[]{}/:\\<>,.#''~@=-+_!£$%^*()]+$';
    if isempty(regexp(s, noquote_needed_re, 'once')) && ...
       isempty(regexp(s, '^"[^"]*"$', 'once')) 
        if regexp(s, '"')
            error('Cannot handle inner " in args...');
        end
        s = ['"' s '"'];
    end
    cmd = [cmd ' ' s];
end
%disp(cmd)
system(cmd);
