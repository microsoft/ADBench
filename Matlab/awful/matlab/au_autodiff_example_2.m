function r = au_autodiff_example_2(params, data)
% Example for autodiff

% Define problem using constants, so symbolic eval will see the problem
% structure
BIGMODEL = 0;

if BIGMODEL
    parents = [0 1 2 3 2 3 1 7 8 7];
    Xlinks = [1 4 8 9 10];
else
    parents = [0 1 2 1];
    Xlinks = [3 4];
end
nlinks = length(parents)
nX = length(Xlinks)

if nargin == 0
    %% TEST CODE
    params = rand(3*nlinks + 3*nX,1)
    tic;
    fn = 'c:\tmp\au_autodiff_example_2_mex.cpp';
    au_autodiff_generate(@au_autodiff_example_2, params, [], fn)
    toc;
    return
end

for k=1:nlinks
    rots{k} = params((k-1)*3+(1:3));
end
for k=1:nlinks
    Rotk = au_rodrigues(rots{k},1,1);
    parent = k;
    while 1
        parent = parents(parent);
        if parent == 0
            break
        end
        Rotk = Rotk * Rotations{parent};
    end    
    Rotations{k} = Rotk;
end

X = params(3*nlinks + [1:nX*3]);

proj = @(X) X(1:2)/X(3);

for k=1:nX
    Xk = X((k-1)*3+(1:3));
    r((k-1)*2+(1:2)) = proj(Rotations{k}*Xk);
end
r = r.';
