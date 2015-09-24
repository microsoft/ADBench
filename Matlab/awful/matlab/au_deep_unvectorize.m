function [obj, num_used] = au_deep_unvectorize(obj, x)
% AU_DEEP_UNVECTORIZE Unflatten arbitrary structure/cell from a linear vector x.
%         x = au_deep_vectorize(obj)
%         obj1 = au_deep_unvectorize(obj, x) % use obj as a template
%         au_assert_equal obj obj1

% awf, aug13

if nargin == 0
    % run tests in au_deep_vectorize
    au_deep_vectorize
    return
end

if iscell(obj)
    % Cell array
    num_used = 0;
    for k=1:numel(obj)
        [obj{k}, n] = au_deep_unvectorize(obj{k}, x(num_used + 1: end));
        num_used = num_used + n;
    end
elseif isstruct(obj)
    if numel(obj) > 1
        % Struct array
        num_used = 0;
        for k=1:numel(obj)
            [obj(k), n] = au_deep_unvectorize(obj(k), x(num_used + 1: end));
            num_used = num_used + n;
        end
    else
        % Individual field
        num_used = 0;
        fields = fieldnames(obj);
        for k = 1:numel(fields)
            field = fields{k};
            [obj.(field), n] = au_deep_unvectorize(obj.(field), x(num_used + 1: end));
            num_used = num_used + n;
        end
    end
else
    % Everything else should be numeric
    num_used = numel(obj);
    % Assign to inputobj, using reshape rather than colon-assign, as may
    % want datatype to match x rather than obj
    obj = reshape(x(1:num_used), size(obj));
end
