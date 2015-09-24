function out = au_map(f, xs, varargin)
% AU_MAP   Map function over container.
%          Combines behaviours of cellfun, arrayfun, with more
%          automatic inference of output type.
%          Examples:
%             au_map(@num2str, rand(3,3))  % produces cell array of strings
%             au_map(@exp, rand(3,3))  % produces numeric array 
%             au_map(@max, rand(3,3), rand(3,3))  % map binary function

if nargin == 0
    %% Test
    help au_map
    
    v = {'a' 'b'};
    v1 = au_map(@(x) ['_' x], v);
    v2 = {'_a' '_b'};
    au_test_equal v1 v2

    X = reshape([1 2; 3 4; 5 6; 7 8], [2 2 2]);
    X1 = au_map(@(x) [x x*11;x*11 x; inf inf], X);
    au_test_equal X1(4,2,1) 33
    X1 = au_map(@(x) sprintf('_%d_ ', x), X);
    au_test_equal X1{2,2,2} '''_8'''
    
    r = rand(3,3);
    au_test_equal au_map(@exp,r) exp(r)

    v0 = au_map(@isequal, {1 2 3}, {1 2 3});
    au_test_equal v0 {1,1,1}
    v0 = au_map(@isequal, [1 2 3], [1 2 3]);
    au_test_equal v0 [1,1,1]
    
    disp('Compare timing to builtin...');
    c= cell(1e2,1e3); for k=1:length(c); c{k} =rand(2,3); end
    tic;cellfun(@max, c, 'uniformoutput', 0); 
    fprintf('Builtin cellfun: '); toc

    tic
    au_map(@max, c);
    fprintf('au_map: '); toc

    tic
    au_map(@max, c, c);
    fprintf('au_map(binary): '); toc

    disp('Compare timing to builtin, more expensive operation...');
    c= cell(1e2,1e1); for k=1:length(c); c{k} =rand(3,3); end
    tic;cellfun(@expm, c, 'uniformoutput', 0); 
    fprintf('Builtin cellfun: '); toc

    % Call the binary one to see how the unary would have been
    % if not implemented in terms of cellfun
    tic
    au_map(@(x,y) expm(x), c, c);
    fprintf('au_map(binary): '); toc
    return
end

if isempty(xs)
    out = xs;
    return
end

if iscell(xs)
    out = cell(size(xs));
    switch length(varargin)
        case 0, out = cellfun(f, xs, 'uniformoutput', 0);
        % The below rather slower on the above benchmark...
        %        case 0, for k=1:numel(xs); out{k} = f(xs{k});; end
        case 1, for k=1:numel(xs); out{k} = f(xs{k},varargin{1}{k}); end
        case 2, for k=1:numel(xs); out{k} = f(xs{k},varargin{1}{k},varargin{2}{k}); end
        case 3, for k=1:numel(xs); out{k} = f(xs{k},varargin{1}{k},varargin{2}{k},varargin{3}{k}); end
        otherwise
            error('unimplemented')
    end
    return
end

if isstruct(xs)
    out = cell(size(xs));
    switch length(varargin)
        case 0, for k=1:numel(xs); out{k} = f(xs(k)); end
        % varags are struct or other? case 1, for k=1:numel(xs); out{k} = f(xs(k),varargin{1}{k}); end
        %case 2, for k=1:numel(xs); out{k} = f(xs(k),varargin{1}{k},varargin{2}{k}); end
        %case 3, for k=1:numel(xs); out{k} = f(xs(k),varargin{1}{k},varargin{2}{k},varargin{3}{k}); end
        otherwise
            error('unimplemented')
    end
    return
end


if isnumeric(xs)
    if isempty(varargin)
        out = arrayfun(f, xs, 'uniformoutput', 0);
    else
        out = cell(size(xs));
        for k=1:numel(xs)
            switch length(varargin)
% special-cased above: case 0, out{k} = f(xs(k));
                case 1, out{k} = f(xs(k),varargin{1}(k));
                case 2, out{k} = f(xs(k),varargin{1}(k),varargin{2}(k));
                case 3, out{k} = f(xs(k),varargin{1}(k),varargin{2}(k),varargin{3}(k));
                otherwise
                    error('unimplemented')
            end
        end
    end
    
    % check if all sizes are the same,
    % if so, kron them
    if iscell(out) && (isnumeric([out{:}]) || islogical([out{:}]))
        szs = au_map(@(x) size(x), out);
        all_same_size = all(all(cat(1, szs{:})));
        if all_same_size
            sz_in = size(xs);
            sz = size(out{1});
            sz(length(sz)+1:length(sz_in)) = 1;
            sz_in(length(sz_in)+1:length(sz)) = 1;
            
            out = reshape(cell2mat(out), sz.*sz_in);
        end
    end
    return
end

error(['Cannot map over class [' class(xs) ']']);

