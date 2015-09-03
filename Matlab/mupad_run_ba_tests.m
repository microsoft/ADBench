function [times_f, times_J] = ...
    mupad_run_ba_tests(params,task_fns,...
    nruns_f,nruns_J,out_file)
%mupad_run_ba_tests
%   compute derivative of ba

addpath('mupad');
addpath('awful\matlab');

ntasks = numel(task_fns);
times_f = Inf(1,ntasks);
times_J = Inf(1,ntasks);
J = cell(1,ntasks);

if ~exist('out_file','var')
    out_file = [];
end

for i=1:ntasks
    disp(['runnning ba: ' num2str(i) '; params: ' num2str(params{i})]);
    [cams, X, w, obs] = load_ba_instance([task_fns{i} '.txt']);
    
    nruns_curr_f = nruns_f(i);
    nruns_curr_J = nruns_J(i);
    
    if nruns_curr_f > 0
        tic
        for j=1:nruns_curr_f
            [~,reproj_err,w_err] = mupad_ba_objective(cams, X, w, obs, false);
        end
        times_f(i) = toc/nruns_curr_f;
    end
    
    if nruns_curr_J > 0
        tic
        for j=1:nruns_curr_J
            [J{i},reproj_err,w_err] = mupad_ba_objective(cams, X, w, obs, true);
        end
        times_J(i) = toc/nruns_curr_J;
    end
    
    if ~isempty(out_file)
        save(out_file,'times_f','times_J','params','J');
    end
end

end