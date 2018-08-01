disp('au_ccode test')
syms u v real
x = [
    sin(u) * cos(log(v))
    sin(u) * sin(log(v))
    cos(u)
    ];
n = cross(diff(x, u), diff (x,v));
nnorm = sqrt(sum(n.^2));

exprs= {nnorm, [x n/nnorm]};
for pass = 1:2
    %%
    out = exprs{pass};
    
    for CSE = 0:1
        % Compute "ground truth" values
        rs = 4;
        cs = 7;
        in_u = randn(rs,cs);
        in_v = rand(rs,cs);
        tic
        out_vals = zeros([size(out) size(in_u)]);
        for i = 1:size(in_u, 1)
            for j = 1:size(in_u, 2)
                o = subs(out, {u,v}, {in_u(i,j), in_v(i,j)});
                out_vals(:,:,i,j) = o;
            end
        end
        toc
        
        s = au_ccode(out, [], CSE);
        
        %%
        fprintf(1, 'codegen\n');
        au_ccode(out, [au_root_dir '/au_ccode_test_mex.cpp'], CSE)
        fprintf(1, 'mex\n');
        mex('-nologo', [au_root_dir '/au_ccode_test_mex.cpp'])
        
        %%
        fprintf(1, 'call\n');
        tic
        out_mex = au_ccode_test_mex(in_u, in_v);
        toc
        
        au_test_equal out_vals out_mex 1e-10 print
    end
end

