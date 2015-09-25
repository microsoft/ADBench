%% set paths and get tools struct array
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release/hand';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python/';
julia_dir = 'C:/Users/t-filsra/Workspace/autodiff/Julia/';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/hand_instances/';
problem_level = 'simple';
% problem_level = 'complicated';
data_dir = [data_dir problem_level];
exe_dir = [exe_dir '_' problem_level '/'];
data_dir = [data_dir '_small/'];
% data_dir = [data_dir '_big/'];
data_dir_est = [data_dir 'est/'];
replicate_point = false;
problem_name = 'hand';

if strcmp(problem_level,'simple')
    tools = get_tools_hand(exe_dir,python_dir,julia_dir);
else
    tools = get_tools_hand_complicated(exe_dir,python_dir,julia_dir);
end
manual_eigen_id = 1;
ntools = numel(tools);

%% generate parameters and order them
params = {100, 192, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 100000};

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
       adimat_run_tests([problem_name problem_level],...
           do_adimat_sparse,data_dir,fns,...
           nruns,nruns,times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_tests([problem_name problem_level],...
           do_adimat_sparse,data_dir,fns,...
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
       adimat_run_tests([problem_name problem_level],...
           do_adimat_sparse,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_tests([problem_name problem_level],...
           do_adimat_sparse,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 5 % mupad
%        mupad_run_ba_tests(params,data_dir,fns,...
%            nruns_f(:,i),nruns_J(:,i),times_file);
   end    
end

% %% transport missing runtimes (from data_dir_est to data_dir)
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

%% read final times
[times_f,times_J] = ...
    read_times(data_dir,data_dir_est,fns,tools,problem_name);

% add finite differences times
for i=1:ntools
    if tools(i).call_type == 6
        nparams = 26;
        if strcmp(problem_level,'complicated')
            nparams = nparams + 2;
        end
        nparams = repmat(nparams,1,numel(params));
        [times_f(:,i), times_J(:,i)] = compute_finite_diff_times_J(tools(i),...
            nparams,times_f);
    end
end

% times_f_relative = bsxfun(@rdivide,times_f,times_f(:,manual_eigen_id));
% times_f_relative(isnan(times_f_relative)) = Inf;
% times_f_relative(times_f_relative==0) = Inf;
times_J_relative = times_J./times_f;
% times_J_relative = bsxfun(@rdivide,times_J,times_J(:,manual_eigen_id));
times_J_relative(isnan(times_J_relative)) = Inf;
times_J_relative(times_J_relative==0) = Inf;
%% output results
save([data_dir 'times_' date],'times_f','times_J','params','tools');

%% plot times
x=[params{:}];

if strcmp(problem_level,'simple')
    levelstr = 'Hand Tracking Simple - ';
else 
    levelstr = 'Hand Tracking Complicated - ';
end
if strcmp(data_dir(end-3:end-1),'big')
    modelstr = 'Hand Model with 10k Vertices';
else 
    modelstr = 'Hand Model with 544 Vertices';
end
xlabel_ = '# correspondences';

plot_log_runtimes(tools,times_J,x,...
    [levelstr 'Jacobian Absolute Runtimes - ' modelstr],...
    'runtime [seconds]',xlabel_);

plot_log_runtimes(tools,times_J_relative,x,...
    [levelstr 'Jacobian Relative Runtimes wrt Objective Runtimes - ' modelstr],...
    'relative runtime',xlabel_);

% to_show=[1 2 6 10:12]; % unique languages for hand
plot_log_runtimes(tools,times_f,x,...
    ['Objective Absolute Runtimes - ' modelstr],...
    'runtime [seconds]',xlabel_);

%% verify results - only simple now
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
bad = {};
num_ok = 0;
num_not_comp = 0;
for i=1:ntasks
    disp(['comparing to adimat: ' num2str(i) '; params: ' num2str(params{i})]);
    [param, data] = load_hand_instance([data_dir 'model/'],...
        [data_dir fns{i} '.txt']);
    fval = hand_objective(param, data);
    opt = admOptions('independents', [1],  'functionResults', {fval});
    [J,~] = admDiffVFor(@hand_objective, 1, param, data, opt);
    
    for j=1:ntools
        if tools(j).call_type < 3
            fn = [data_dir fns{i} '_J_' tools(j).ext '.txt'];
            if exist(fn,'file')
                Jexternal = load_J(fn);
                tmp = norm(J(:) - Jexternal(:)) / norm(J(:));
                if tmp < 1e-5
                    num_ok = num_ok + 1;
                else
                    bad{end+1} = {fn, tmp};
                end
            else
                disp([tools(j).name ': not computed']);
                num_not_comp = num_not_comp + 1;
            end
        end
    end
end
disp(['num ok: ' num2str(num_ok)]);
disp(['num bad: ' num2str(numel(bad))]);
disp(['num not computed: ' num2str(num_not_comp)]);
for i=1:numel(bad)
    disp([bad{i}{1} ' : ' num2str(bad{i}{2})]);
end