function [times_f, times_J, times_sparse] = ...
    adimat_run_ba_tests(do_adimat_sparse,data_dir,task_fns,...
    nruns_f,nruns_J,times_file)
%adimat_run_gmm_tests
%   compute derivative of gmm

ntasks = numel(task_fns);
times_f = Inf(1,ntasks);
times_J = Inf(1,ntasks);
times_sparse = Inf(1,ntasks);

if ~exist('times_file','var')
    times_file = [];
else
    if exist(out_file,'file')
        load(out_file,'times_f','times_J');
    end
end

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');

if do_adimat_sparse
    do_F_mode = true;
    adimat_translate_if_new(@ba_objective, [1 2 3], do_F_mode);
else
    do_F_mode = false;
    adimat_translate_if_new(@ba_compute_reproj_err, [1 2 3], do_F_mode);
    adimat_translate_if_new(@compute_w_err, [1], do_F_mode);
end

for i=1:ntasks
    disp(['runnning ba: ' num2str(i)]);
    [cams, X, w, obs] = load_ba_instance([data_dir task_fns{i} '.txt']);
    
    nruns_curr_f = nruns_f(i);
    nruns_curr_J = nruns_J(i);
    
    if nruns_curr_f+nruns_curr_J == 0
        continue;
    end
    
    if nruns_curr_f > 0
        tic
        for j=1:nruns_curr_f
            [fval1, fval2] = ba_objective(cams,X,w,obs);
        end
        times_f(i) = toc/nruns_curr_f;
    end
    
    if nruns_curr_J > 0
        
        if do_adimat_sparse
            tic
            nzpattern = create_nonzero_pattern(size(cams,2),size(X,2),obs);
            colFunc = @cpr;
            [colResults{1:2}] = colFunc(nzpattern);
            coloring = colResults{2};
            compressedSeedMatrix = admCreateCompressedSeedSparse(coloring);
            times_sparse(i) = toc;
        end
        
        tic
        for j=1:nruns_curr_J
            if do_adimat_sparse
                [J, fval_] = adimat_compute_sparse_J(@d_ba_objective,...
                    {cams,X,w,obs},2,[1 2 3],nzpattern,coloring,...
                    compressedSeedMatrix);
            else
                [J, fval_] = adimat_run_ba(do_F_mode,...
                    do_adimat_sparse,cams,X,w,obs);
            end
        end
        times_J(i) = toc/nruns_curr_J;
    end
    
    if ~isempty(times_file)
        save(times_file,'times_f','times_J','params','times_sparse');
    end
end

end
