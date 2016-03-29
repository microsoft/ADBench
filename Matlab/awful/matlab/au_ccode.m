function out = au_ccode(symobj, filename, DO_CSE, SIMPLIFY_TMAX)
% AU_CCODE    Generate optimized C code from symbolic expression.
%             AU_CCODE(SYMEXPR) returns a string
%             AU_CCODE(SYMEXPR, FILENAME) writes to FILENAME
%             AU_CCODE(SYMEXPR, FILENAME, 0) turns off CSE
%             AU_CCODE(SYMEXPR, FILENAME, 0, TMAX) stops simplify after TMAX seconds
%             
%          EXAMPLE:
%             syms x y real
%             au_ccode(x^3 + x^2*y)
%             au_ccode(simplify(x^3 + x^2*y))

% Author: awf@microsoft.com

if nargin == 0
    au_ccode_test
    
    return
end

if nargin < 2
    filename = [];
end

if nargin < 3
    DO_CSE = 1;
end

if nargin < 4
    SIMPLIFY_TMAX = Inf;
end

t=clock;
if 0
  fprintf('au_ccode: expr size= ');
  l=length(char(symobj));
  fprintf('%.2fMB (took %.1f sec to measure), ', l/1024/1024, etime(clock,t))
else
  fprintf('au_ccode: symvars ');
end

% Capture symvars and size before CSE
vars = symvar(symobj);
[out_rows,out_cols] = size(symobj);

% Simplify expression
if SIMPLIFY_TMAX > 0
  fprintf('simplify ');
  symobj = simplify(symobj, 'Seconds', SIMPLIFY_TMAX);
  fprintf('[%.1fsec], ', etime(clock,t));
end

% Now do common subexpression elimination if required
if DO_CSE
  t=clock;
  fprintf('cse ');
  symobj = feval(symengine, 'generate::optimize', symobj);
  fprintf('[%.1fsec]', etime(clock,t));
end
fprintf('C, ');
c = feval(symengine, 'generate::C', symobj);
fprintf('manip...\n');
cstring = strrep(char(c), '\n', sprintf('\n'));

% Replace "t454 = " with "double t454 ="
cstring = regexprep(cstring, '\<(\w+) =', '  double $&');

% Replace "t343[r][c] =" with "out_ptr[c * out_rows + r];
if out_rows * out_cols == 1
    % Singleton input produces rather different ccode, the last assignment
    % is the output-setter
    [startindex, endindex] = regexp(cstring, '\<double t[01] = ');
    cstring = [cstring(1:startindex(end)-1) ...
        'out_ptr[0] =' cstring(endindex(end):end)];
else
    % Vector input is easy to pattern-match, the [][] identify the output
    % assignments
    cstring = regexprep(cstring, '\<(\w+)\[(\d+)\]\[(\d+)\] =', ...
    'out_ptr[$3 * out_rows + $2] =');
end

%% Return if not writing to file
if isempty(filename)
    out = cstring;
    return
end

%%
% If there's a filename, make it a mexFunction
if ischar(filename)
    fd = fopen(filename, 'w');
else
    fd = filename;
end

nvars = length(vars);
GetVars = '';
for vi = 1:nvars
    GetVars = sprintf('%s\n  double* ptr_%s = mxGetPr(prhs[%d]);', ...
        GetVars, char(vars(vi)), vi - 1);
    fprintf('au_ccode: input var %d [%s]\n', vi, char(vars(vi)));
end

body = '  /* inner loop */';
for vi = 1:nvars
    v = char(vars(vi));
    in_v = ['in_' v];
    body = sprintf('%s\n  double %s = ptr_%s[c_in*mrows + r_in];\n', body, in_v, v);
    cstring = regexprep(cstring, ['\<' v '\>'], regexptranslate('escape', in_v));
end
body = sprintf('%s\n%s', body, cstring);

% Get Template Text
tfd = fopen('au_ccode_template.cpp', 'r');
template = fread(tfd, inf, 'char');
fclose(tfd);

varname = inputname(1);
if isempty(varname)
    varname = '[Anonymous expression]';
end

template = char(template');
template = strrep(template, '@VarName', varname);
template = strrep(template, '@NVars', num2str(nvars));
template = strrep(template, '@Body', body);
template = strrep(template, '@OutRows', num2str(out_rows));
template = strrep(template, '@OutCols', num2str(out_cols));
template = strrep(template, '@GetVars', GetVars);

fprintf(fd, '%s', template);
if ischar(filename)
    fclose(fd);
end
