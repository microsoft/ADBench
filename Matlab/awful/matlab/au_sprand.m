function S = au_sprand(rows, cols, density)
% AU_SPRAND   Like sprand, but faster.
%           Type HELP SPRAND for more info

if nargin == 0
    %% test code
    rows = 1e6;
    cols = 1e5;
    n=1e6;
    density = n/(rows*cols);
    tic
    R = au_sprand(rows,cols,density);
    toc
    tic
    R = sprand(rows,cols,density);
    toc
    return
end

n = ceil(rows*cols*density);

s = cumsum(rand(n,1));
s = s*((rows*cols)/s(end));
s = floor(s);

while true
    inds = (diff(s)==0);
    if sum(inds) == 0
        break
    end
    s(inds) = [];
end

n_actual = numel(s);
if (n_actual < n*.99)
    warning('au_sprand:badapprox', 'Actual density below 99%% of true');
end

jj = floor(s/rows)+1;
ii = rem(s,rows)+1;

S = au_sparse(int32(ii), int32(jj), rand(n_actual,1));
