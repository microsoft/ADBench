function new_path = au_strip_path(path, RE)
% AU_STRIP_PATH  Remove directories matching REGEXP from PATH
%                new_path = au_strip_path(path, RE)
%                Assumes PATH is a semicolon-separated string

if nargin == 0
    %% Test
    p = 'c:\a\b;c:\d\e;c:\d\f;c:\b\c;c:\a\e';
    au_test_equal  au_strip_path(p,'^c:\\a') '''c:\d\e;c:\d\f;c:\b\c'''
    au_test_equal  au_strip_path(p,'^C:\\A') '''c:\d\e;c:\d\f;c:\b\c'''
    au_test_equal  au_strip_path(p,'^C:\\D') '''c:\a\b;c:\b\c;c:\a\e'''
   
    return
end


p = strsplit(path,';')'; 
keep_inds = cellfun(@(x) isempty(regexpi(x, RE, 'once')), p);
new_path = strjoin(p(keep_inds), ';');
