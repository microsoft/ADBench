function [tf, tJ] = ...
    ADiMat_hand(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit, do_adimat_sparse)
%adimat_hand
%   compute derivative of hand

% NOTE this is simple, find complicated differences in adimat_run_tests

if nargin < 7
    do_adimat_sparse = false;
end

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

addpath('../../submodules/adimat-0.6.2-5288');
ADiMat_startup
addpath('../../submodules/awful/matlab');
addpath('../matlab-common');

do_F_mode = true;
adimat_translate_if_new(@hand_objective_complicated, [1 2], do_F_mode);

[params, data, us] = load_hand_instance(fullfile(dir_in,'model'),...
    fullfile(dir_in,[fn '.txt']));
run_objective = @() hand_objective_complicated(params, us, data);

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
        tic
        nzpattern = create_nonzero_pattern_hand(data);
        colFunc = @cpr;
        [colResults{1:2}] = colFunc(nzpattern);
        coloring = colResults{2};
        compressedSeedMatrix = admCreateCompressedSeedSparse(coloring);
        time_sparse = toc;
        run_objective_d = @() adimat_compute_sparse_J(@d_hand_objective,...
            {params,data},1,[1],nzpattern,coloring,...
            compressedSeedMatrix);
    else
        run_objective_d = @() adimat_run_hand(do_F_mode,...
            params,data,us);
    end

    tic
    for i=1:nruns_J
        [J, fval_] = run_objective_d();
    end
    tJ = toc/nruns_J;
else
    tJ = 0;
end

fid=fopen([dir_out fn '_times_ADiMat.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end