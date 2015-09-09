%% get tools
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release/hand/';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python/';
julia_dir = 'C:/Users/t-filsra/Workspace/autodiff/Julia/';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/hand_instances/';
data_dir_est = [data_dir 'est/'];
replicate_point = false;
problem_name = 'hand';

tools = get_tools_hand(exe_dir,python_dir,julia_dir);
manual_eigen_id = 1;
ntools = numel(tools);

%% generate parameters and order them
params = {[192 544], [500 1544], [1000 2544],[2000 3544],...
    [4000 4544],[8000 5544],[16000 6544],[32000 7544],[64000 8544],[100000 10000]};

for i=1:numel(params)
    disp(num2str(params{i}));
end

fns = {};
for i=1:numel(params)
    fns{end+1} = [problem_name num2str(i)];
end
ntasks = numel(params);
% save(['params_' problem_name '.mat'],'params');

%% write script for running tools once
fn_run_once = 'run_tools_once.mk';
nruns=ones(ntasks,ntools);
write_script(fn_run_once,params,data_dir,data_dir_est,fns,tools,...
    nruns,nruns);

%% run all tools once - runtimes estimates
% tic
% system(fn_run_once);
% toc

% tools ran from matlab
nruns = ones(1,ntasks);
for i=1:ntools
   times_file = [data_dir_est problem_name '_times_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_sparse = false;
       adimat_run_tests(problem_name,do_adimat_sparse,data_dir,fns,...
           nruns,nruns,times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_tests(problem_name,do_adimat_sparse,data_dir,fns,...
           nruns,nruns,times_file);
   elseif tools(i).call_type == 5 % mupad
%        mupad_run_hand_tests(params,data_dir,fns,...
%            nruns,nruns,times_file);
   end    
end

%% read time estimates & determine nruns for everyone
[times_est_f,times_est_J,up_to_date_mask] = ...
    read_times(data_dir,data_dir_est,fns,tools,problem_name);

nruns_f = determine_n_runs(times_est_f);
nruns_J = determine_n_runs(times_est_J);
save([data_dir_est 'estimates_backup.mat'],'nruns_f','nruns_J',...
    'times_est_f','times_est_J','up_to_date_mask');
nruns_f = nruns_f .* ~up_to_date_mask;
nruns_J = nruns_J .* ~up_to_date_mask;

%% write script for running tools
fn_run_experiments = 'run_experiments.mk';
write_script(fn_run_experiments,params,data_dir,data_dir,...
    fns,tools,nruns_f,nruns_J,replicate_point);

%% run all experiments
% tic
% system(fn_run_experiments);
% toc

% tools ran from matlab
for i=1:ntools
   times_file = [data_dir problem_name '_times_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_sparse = false;
       adimat_run_tests(problem_name,do_adimat_sparse,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_tests(problem_name,do_adimat_sparse,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 5 % mupad
%        mupad_run_ba_tests(params,data_dir,fns,...
%            nruns_f(:,i),nruns_J(:,i),times_file);
   end    
end

%% Transport runtimes
% load([data_dir_est 'estimates_backup.mat']);
% [times_fixed_f,times_fixed_J] = ...
%     read_times(data_dir,'-',fns,tools,problem_name);
% mask_f = (nruns_f==0) & ~up_to_date_mask & ~isinf(times_est_f);
% mask_J = (nruns_J==0) & ~up_to_date_mask & ~isinf(times_est_J);
% times_fixed_f(mask_f) = times_est_f(mask_f);
% times_fixed_J(mask_J) = times_est_J(mask_J);
% for i=1:ntools
%     if tools(i).call_type < 3
%         postfix = ['_times_' tools(i).ext '.txt'];
%         for j=1:ntasks
%             if any([mask_f(j,i) mask_J(j,i)])
%                 fn = [data_dir fns{j} postfix];
%                 fid = fopen(fn,'w');
%                 fprintf(fid,'%f %f\n',times_fixed_f(j,i),times_fixed_J(j,i));
%                 fprintf(fid,'tf tJ');
%                 fclose(fid);
%             end
%         end
%     end
% end
% 
%% read final times
[times_f,times_J] = ...
    read_times(data_dir,data_dir_est,fns,tools,problem_name);

times_f_relative = bsxfun(@rdivide,times_f,times_f(:,manual_eigen_id));
times_f_relative(isnan(times_f_relative)) = Inf;
times_f_relative(times_f_relative==0) = Inf;
% times_relative = times_J./times_f;
times_J_relative = bsxfun(@rdivide,times_J,times_J(:,manual_eigen_id));
times_J_relative(isnan(times_J_relative)) = Inf;
times_J_relative(times_J_relative==0) = Inf;

%% output results
save([data_dir 'times_' date],'times_f','times_J','params','tools');

%% plot times
x=[params{:}]; x=x(1:2:end);

plot_log_runtimes(tools,times_J,x,...
    'Jacobian runtimes','runtime [seconds]',true);

plot_log_runtimes(tools,times_J_relative,x,...
    'Jacobian runtimes relative to Manual, C++','runtime',false);

plot_log_runtimes(tools,times_f,x,...
    'objective runtimes','runtime [seconds]',true);

plot_log_runtimes(tools,times_f_relative,x,...
    'objective runtimes relative to Manual, C++','runtime',false);
