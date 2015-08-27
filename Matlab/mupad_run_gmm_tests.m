function [times_f, times_J] = ...
    mupad_run_gmm_tests(params,task_fns,...
    nruns_f,nruns_J,out_file)
%mupad_run_gmm_tests
%   compute derivative of gmm

addpath('mupad');
addpath('awful\matlab');

ntasks = numel(task_fns);
times_f = Inf(1,ntasks);
times_J = Inf(1,ntasks);

if ~exist('out_file','var')
    out_file = [];
end

for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    [paramsGMM,x,hparams] = load_gmm_instance([task_fns{i} '.txt']);
    
    nruns_curr_f = nruns_f(i);
    nruns_curr_J = nruns_J(i);
    
    if nruns_curr_f > 0
        tic
        [ J, err ] = mupad_gmm_objective(nruns_curr_f, paramsGMM, x, ...
            hparams, false);
        if ~isempty(J)
            times_f(i) = toc/nruns_curr_f;
        end
    end
    
    if nruns_curr_J > 0
        tic
        [ J, err ] = mupad_gmm_objective(nruns_curr_J, paramsGMM, x,...
            hparams, true);
        if ~isempty(J)
            times_J(i) = toc/nruns_curr_J;
        end
    end
    
    if ~isempty(out_file)
        save(out_file,'times_f','times_J','params');
    end
end

end