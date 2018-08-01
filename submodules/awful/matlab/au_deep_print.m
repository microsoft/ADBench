function au_deep_print(obj, prefix, suffix)

% AU_DEEP_PRINT Hierarchical print of object.

% Author: awf
% Date: Jun 2014

if nargin == 0
    a = 2;
    b.a = randn(2,3,4);
    b.b = [1 1];
    c = {randn(3,1), randn(1,1,2)};
    b.c.d = c;
    d = cell(2,1,3);
    b1 = b;
    b1.b = [2 3];
    obj = {a,{b,c;d,b1}};
    au_deep_print(obj);
    return
end

if nargin < 2
    prefix = inputname(1);
end

if nargin < 3
    suffix = sprintf('\n');
end

if iscell(obj)
    for k=1:numel(obj)
        subprefix = sprintf('%s{%d}', prefix, k);
        au_deep_print(obj{k}, subprefix, suffix);
    end
elseif isstruct(obj)
    if numel(obj) > 1
        for k=1:numel(obj)
            subprefix = sprintf('%s(%d)', prefix, k);
            au_deep_print(obj(k), subprefix, suffix);
        end
    else
        fields = fieldnames(obj);
        for k = 1:numel(fields)
            field = fields{k};
            subprefix = sprintf('%s.%s', prefix, field);
            au_deep_print(obj.(field), subprefix, suffix);
        end
    end
else
    fprintf('%s = %s%s', prefix, au_mat2str(obj, 4, 12), suffix);
end
