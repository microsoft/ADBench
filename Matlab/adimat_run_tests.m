function [times_f, times_J, times_sparse] = ...
    adimat_run_tests(problem_name,do_adimat_sparse,data_dir,task_fns,...
    nruns_f,nruns_J,times_file)

isba = strcmp(problem_name,'ba');
ishand = strcmp(problem_name,'hand');

ntasks = numel(task_fns);
times_f = Inf(1,ntasks);
times_J = Inf(1,ntasks);
times_sparse = Inf(1,ntasks);

if ~exist('times_file','var')
    times_file = [];
else
    if exist(times_file,'file')
        load(times_file,'times_f','times_J');
    end
end

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');

if isba
    if do_adimat_sparse
        do_F_mode = true;
        adimat_translate_if_new(@ba_objective, [1 2 3], do_F_mode);
    else
        do_F_mode = false;
        adimat_translate_if_new(@ba_compute_reproj_err, [1 2 3], do_F_mode);
        adimat_translate_if_new(@compute_w_err, [1], do_F_mode);
    end
elseif ishand
    do_F_mode = true;
    adimat_translate_if_new(@hand_objective, [1], do_F_mode);
end

for i=1:ntasks
    disp(['runnning instance: ' num2str(i)]);
    if isba
        [cams, X, w, obs] = load_ba_instance([data_dir task_fns{i} '.txt']);
        run_objective = @() ba_objective(cams,X,w,obs);
    elseif ishand
        [params, data] = load_hand_instance(fullfile(data_dir,'model'),...
            fullfile(data_dir,[task_fns{i} '.txt']));
        run_objective = @() hand_objective(params, data);
    end
    
    nruns_curr_f = nruns_f(i);
    nruns_curr_J = nruns_J(i);
    
    if nruns_curr_f+nruns_curr_J == 0
        continue;
    end
    
    if nruns_curr_f > 0
        tic
        for j=1:nruns_curr_f
            fval = run_objective();
        end
        times_f(i) = toc/nruns_curr_f;
    end
    
    if nruns_curr_J > 0
        
        if do_adimat_sparse
            tic
            if isba
                nzpattern = create_nonzero_pattern_ba(size(cams,2),size(X,2),obs);
            elseif ishand
                nzpattern = create_nonzero_pattern_hand(data);
            end
            colFunc = @cpr;
            [colResults{1:2}] = colFunc(nzpattern);
            coloring = colResults{2};
            compressedSeedMatrix = admCreateCompressedSeedSparse(coloring);
            times_sparse(i) = toc;
            if isba
                run_objective_d = @() adimat_compute_sparse_J(@d_ba_objective,...
                    {cams,X,w,obs},2,[1 2 3],nzpattern,coloring,...
                    compressedSeedMatrix);
            elseif ishand
                run_objective_d = @() adimat_compute_sparse_J(@d_hand_objective,...
                    {params,data},1,[1],nzpattern,coloring,...
                    compressedSeedMatrix);
            end
        else
            if isba
                run_objective_d = @() adimat_run_ba(do_F_mode,...
                    cams,X,w,obs);
            elseif ishand
                run_objective_d = @() adimat_run_hand(do_F_mode,...
                    params,data);
            end
        end
        
        tic
        for j=1:nruns_curr_J
            [J, fval_] = run_objective_d();
        end
        times_J(i) = toc/nruns_curr_J;
    end
    
    if ~isempty(times_file)
        save(times_file,'times_f','times_J','times_sparse');
    end
end

end
