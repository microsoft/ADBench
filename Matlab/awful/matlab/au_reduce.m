function out = au_reduce(f, xs, base)
% AU_REDUCE Apply binary function to container elements, left-associative

% awf, dec13

if nargin == 0
    %% Test code
    au_test_equal au_reduce(@plus,[]) []
    au_test_equal au_reduce(@plus,[],1) 1
    au_test_equal au_reduce(@plus,[2]) []
    au_test_equal au_reduce(@plus,[2],1) 3
    au_test_equal au_reduce(@plus,[2,3]) 5
    au_test_equal au_reduce(@plus,[2,3],1) 6
    au_test_equal au_reduce(@plus,[2,3,7]) 12
    au_test_equal au_reduce(@plus,[2,3,7],1) 13
    au_test_equal au_reduce(@plus,{}) []
    au_test_equal au_reduce(@plus,{},1) 1
    au_test_equal au_reduce(@plus,{2}) []
    au_test_equal au_reduce(@plus,{2},1) 3
    au_test_equal au_reduce(@plus,{2,3}) 5
    au_test_equal au_reduce(@plus,{2,3},1) 6
    au_test_equal au_reduce(@plus,{2,3,4}) 9
    au_test_equal au_reduce(@plus,{2,3,4},1) 10
    
    au_test_equal('au_reduce(@(x,y) [x ''_'' y],{''a'',''b'',''c''})',  '''a_b_c''')
    return
end

if nargin < 3
    % no base
    if numel(xs) < 2
        out=[];
    else
        if iscell(xs)
            out = f(xs{1}, xs{2});
            for k=3:length(xs)
                out = f(out, xs{k});
            end
        else
            out = f(xs(1), xs(2));
            for k=3:length(xs)
                out = f(out, xs(k));
            end
        end
    end
else
    % have base
    out = base;
    if iscell(xs)
        for k=1:length(xs)
            out = f(out, xs{k});
        end
    else
        for k=1:length(xs)
            out = f(out, xs(k));
        end
    end
end
