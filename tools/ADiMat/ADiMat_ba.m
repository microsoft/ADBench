function [tf, tJ] = ...
    ADiMat_ba(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit, do_adimat_sparse)
%adimat_run_gmm_tests
%   compute derivative of gmm

if nargin < 7
    do_adimat_sparse = false;
end

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

addpath('../../submodules/adimat-0.6.2-5288');
ADiMat_startup
addpath('../../submodules/awful/matlab');
addpath('../matlab-common');

if do_adimat_sparse
    do_F_mode = true;
    adimat_translate_if_new(@ba_objective, [1 2 3], do_F_mode);
else
    do_F_mode = false;
    adimat_translate_if_new(@ba_compute_reproj_err, [1 2 3], do_F_mode);
    adimat_translate_if_new(@compute_w_err, [1], do_F_mode);
end

[cams, X, w, obs] = load_ba_instance([dir_in fn '.txt']);
run_objective = @() ba_objective(cams,X,w,obs);

if nruns_f > 0
    tic
    for i=1:nruns_f
        fval = run_objective();
    end
    tf = toc/nruns_f;
else
    tf = 0;
end

if nruns_J > 0
    if do_adimat_sparse
        nzpattern = create_nonzero_pattern_ba(size(cams,2),size(X,2),obs);
        colFunc = @cpr;
        [colResults{1:2}] = colFunc(nzpattern);
        coloring = colResults{2};
        compressedSeedMatrix = admCreateCompressedSeedSparse(coloring);
        run_objective_d = @() adimat_compute_sparse_J(@d_ba_objective,...
            {cams,X,w,obs},2,[1 2 3],nzpattern,coloring,...
            compressedSeedMatrix);
    else
        run_objective_d = @() adimat_run_ba(do_F_mode,...
            cams,X,w,obs);
    end

    tic
    for i=1:nruns_J
        [J, fval_] = run_objective_d();
    end
    tJ = toc/nruns_J;
else
    tJ = 0
end

fid=fopen([dir_out fn '_times_ADiMat.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end