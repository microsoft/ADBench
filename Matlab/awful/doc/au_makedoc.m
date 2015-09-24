function au_makedoc

docdir = [au_root_dir '\..\doc\'];

matlab_files = what(au_root_dir);

ok_to_ignore = {
    'au_autodiff_example_1.m'
    'au_autodiff_example_2.m'
    'au_bsx_test.m'
    'au_ccode_test.m'
    'au_levmarq_test.m'
    'au_mex.m'
    'au_mex_test.m'
    'au_mexall.m'
    'au_mfilename_test.m'
    'au_prmat_test.m'
    'au_whist_test.m'
    'au_test_test.m'
    'au_sparse_test.m'
    'Contents.m'
    };

%% Make MatlabAllHelp.html
fn = [docdir 'MatlabAllHelp.html'];
fprintf(2, 'Writing to [%s]\n', fn);
fd = fopen(fn, 'wt');
%fprintf(fd, '<html><title>MatlabAllHelp</title><body>\n');
for mfile = (matlab_files.m)'
    thismfile = mfile{1};
    if any(cell2mat(strfind(ok_to_ignore, thismfile)))
        continue
    end
    
    h = help(thismfile);
    if regexp(h, '^[ \t\n]*AU_')
        summary_line = regexprep(h, '\n.*', '');
        %fprintf(1, '%s\n', summary_line);
        
        h = regexprep(h, '\n', '<br/>\n');
        fprintf(fd,'<p/><hr/>\n%s\n<pre>\n%s</pre>\n\n', thismfile, h);
    else
        fprintf(2, 'Ignoring [%s]\n', thismfile);
        fprintf('Help is:\n%s\n', h);
    end
end
fprintf(fd, '</body></html>\n');
fclose(fd);
fprintf('Created [%s]\n', fn);

%% Make contents.m and Contents.html
template = fopen([docdir 'Contents_template.txt']);
fn_m = [au_root_dir '\Contents.m'];
fprintf(2, 'Writing to [%s]\n', fn_m);
fd_m = fopen(fn_m, 'wt');
fprintf(fd_m, 'function AUTO_GENERATED_FROM_Contents_template_txt\n');
out_m_tr = @(word, summary) fprintf(fd_m, '%% %-15s %s\n', word, summary);
out_m_header = @(line) fprintf(fd_m, '%% *%s*\n', line);
out_m_line = @(line) fprintf(fd_m, '%% %s\n', line);

fn_html = [docdir 'Contents.html'];
fprintf(2, 'Writing to [%s]\n', fn_html);
fd_html = fopen(fn_html, 'wt');
fprintf(fd_html, '<!-- AUTO_GENERATED_FROM_Contents_template_txt -->\n');
table_is_open = false;

while ~feof(template)
    l = fgetl(template);
    if regexp(l, '^#')
        continue
    end
    
    % line types in Contents_template, and what they map to
    % ^!WORD        ->   WORD Summary_line(WORD)
    % ^  WORD +     ->   WORD \'
    % *TEXT*        -> *TEXT*   (or <h4> in html)
    % .*            -> \1
    
    % replace !words with help text
    [startindex, endindex] = regexp(l, '![A-Za-z0-9_]+');
    if startindex
        word = l(startindex+1:endindex);
        % pull the summary line from the WORD.m file using help
        h = help(word);
        summary_line = regexprep(h, '\n.*', '');
        summary_line = regexprep(summary_line, '^ *[^ ]+ *','');
        out_html_tr(word, summary_line);
        out_m_tr(word, summary_line);
        continue;
    end
    
    names = regexp(l, '^ +(?<word>[^ ]+) +(?<summary>.*)', 'names');
    if ~isempty(names)
        out_html_tr(names.word, names.summary);
        out_m_tr(names.word, names.summary);
        continue;
    end
    
    % The rest are not table entries, so close table if open.
    ensure_table_closed
    
    names = regexp(l, '^\*(?<line>.*)\* *$', 'names');
    if ~isempty(names)
        out_html_header(names.line);
        out_m_header(names.line);
        continue;
    end
    
    out_html_line(l);
    out_m_line(l);

end
fclose(fd_m);
fclose(fd_html);
fclose(template);

%   </tbody>
% </table>
%
%     <h4>Symbolic toolbox helpers</h4>
% <table width="600px">
%   <tbody>
%     <tr>
%       <td>au_coeff</td>
%       <td>Coefficients of symbolic polynomial</td>
%     </tr>
%     <tr>
%       <td>au_ccode</td>
%       <td>Convert symbolic expression to C with common subexpression elimination</td>
%     </tr>
%     <tr>
%       <td>au_autodiff_generate</td>
%       <td>Symbolic differentiation and code generation</td>
%     </tr>

    function out_html_tr(word, summary)
        if ~table_is_open
            fprintf(fd_html, '<table width="600px">  <tbody>\n');
            table_is_open = true;
        end
        
        fprintf(fd_html, '<tr>\n');
        fprintf(fd_html, '   <td>%s</td>\n', word);
        fprintf(fd_html, '   <td>%s</td>\n', summary);
        fprintf(fd_html, '</tr>\n');
    end

    function out_html_header(line)
        fprintf(fd_html, '<h4>%s</h4>\n', line);
    end

    function out_html_line(line)
        fprintf(fd_html, '%s\n', line);
    end

    function ensure_table_closed
        if table_is_open
            fprintf(fd_html, '</tbody></table>\n');
            table_is_open = false;
        end
    end
        
end
