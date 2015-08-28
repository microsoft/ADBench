function [times_f, times_J] = ...
    adimat_run_gmm_tests(do_adimat_vector,params,data_dir,task_fns,...
    nruns_f,nruns_J,J_file,times_file,replicate_point)
%adimat_run_gmm_tests
%   compute derivative of gmm

ntasks = numel(task_fns);
do_F_mode = false;
times_f = zeros(1,ntasks);
times_J = zeros(1,ntasks);
J = cell(1,ntasks);

if ~exist('times_file','var')
    times_file = [];
end
if ~exist('J_file','var')
    J_file = [];
end

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
independents = [1 2 3];

if do_adimat_vector
    adimat_translate_if_new(@gmm_objective_vector_repmat, independents);
else
    adimat_translate_if_new(@gmm_objective, independents);
end

for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    [paramsGMM,x,hparams] = load_gmm_instance(...
        [data_dir task_fns{i} '.txt'],replicate_point);
    
    nruns_curr_f = nruns_f(i);
    nruns_curr_J = nruns_J(i);
    
    if do_adimat_vector
        objective = @gmm_objective_vector_repmat;
    else
        objective = @gmm_objective;
    end
    
    if nruns_curr_f > 0
        tic
        for j=1:nruns_curr_f
            fval = objective(paramsGMM.alphas,paramsGMM.means,...
                paramsGMM.inv_cov_factors,x,hparams);
        end
        times_f(i) = toc/nruns_curr_f;
    end
    
    if nruns_curr_J > 0
        tic
        for j=1:nruns_curr_J
            [J{i}, fval_] = adimat_run_gmm(do_F_mode,do_adimat_vector,...
                paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
                x,hparams);
        end
        times_J(i) = toc/nruns_curr_J;
    end
    
    if ~isempty(times_file)
        save(times_file,'times_f','times_J','params');
    end
    if ~isempty(J_file)
        save(J_file,'J','params');
    end
end

end