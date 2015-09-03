%% get tools
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release/ba/';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python/';
julia_dir = 'C:/Users/t-filsra/Workspace/autodiff/Julia/';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/ba_instances/';
data_dir_est = [data_dir 'est/'];

tools = get_tools_ba(exe_dir,python_dir,julia_dir);
manual_eigen_id = 1;
ntools = numel(tools);

%% generate parameters and order them
params = generate_ba_instance_params;

for i=1:numel(params)
    disp(num2str(params{i}));
end

fns = {};
for i=1:numel(params)
    fns{end+1} = ['ba' num2str(i)];
end
ntasks = numel(params);
save('params_ba.mat','params');

%% write instances into files
addpath('awful/matlab')
for i=1:ntasks
    
    n = params{i}(1);
    m = params{i}(2);
    p = params{i}(3);
    
    rng(1);
    [cams,X,w,obs] = generate_random_ba_instance(1,1,1);
    save_ba_instance([data_dir fns{i} '.txt'], cams, X, w, obs, n, m, p);
end

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
   times_file = [data_dir_est 'ba_times_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_sparse = false;
       adimat_run_ba_tests(do_adimat_sparse,data_dir,fns,...
           nruns,nruns,times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_ba_tests(do_adimat_sparse,data_dir,fns,...
           nruns,nruns,times_file);
   elseif tools(i).call_type == 5 % mupad
       mupad_run_ba_tests(params,data_dir,fns,...
           nruns,nruns,times_file);
   end    
end

%% read time estimates & determine nruns for everyone
[times_est_f,times_est_J,up_to_date_mask] = ...
    read_times(data_dir,data_dir_est,fns,tools);

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
   times_file = [data_dir 'ba_times_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_sparse = false;
       adimat_run_ba_tests(do_adimat_sparse,params,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_sparse = true;
       adimat_run_ba_tests(do_adimat_sparse,params,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   elseif tools(i).call_type == 5 % mupad
       mupad_run_ba_tests(params,data_dir,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   end    
end

%% Transport runtimes
load([data_dir_est 'estimates_backup.mat']);
[times_fixed_f,times_fixed_J] = ...
    read_times(data_dir,'-',fns,tools);
mask_f = (nruns_f==0) & ~up_to_date_mask & ~isinf(times_est_f);
mask_J = (nruns_J==0) & ~up_to_date_mask & ~isinf(times_est_J);
times_fixed_f(mask_f) = times_est_f(mask_f);
times_fixed_J(mask_J) = times_est_J(mask_J);
for i=1:ntools
    if tools(i).call_type < 3
        postfix = ['_times_' tools(i).ext '.txt'];
        for j=1:ntasks
            if any([mask_f(j,i) mask_J(j,i)])
                fn = [data_dir fns{j} postfix];
                fid = fopen(fn,'w');
                fprintf(fid,'%f %f\n',times_fixed_f(j,i),times_fixed_J(j,i));
                fprintf(fid,'tf tJ');
                fclose(fid);
            end
        end
    end
end

%% read final times
[times_f,times_J,up_to_date_mask] = ...
    read_times(data_dir,data_dir_est,fns,tools);

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
lw = 2;
msz = 7;
x=[params{:}]; x=x(3:3:end);

plot_log_runtimes(params,tools,times_J,...
    'Jacobian runtimes','runtime [seconds]',true);

plot_log_runtimes(params,tools,times_J_relative,...
    'Jacobian runtimes relative to Manual, C++','runtime',false);

plot_log_runtimes(params,tools,times_f,...
    'objective runtimes','runtime [seconds]',true);

plot_log_runtimes(params,tools,times_f_relative,...
    'objective runtimes relative to Manual, C++','runtime',false);

%% do 2D plots
% tool_id = adimat_id-1;
% vals_J = zeros(numel(d_all),numel(k_all));
% vals_relative = vals_J;
% for i=1:ntasks
%     d = params{i}(1);
%     k = params{i}(2);
%     vals_relative(d_all==d,k_all==k) = times_relative(i,tool_id);
%     vals_J(d_all==d,k_all==k) = times_J(i,tool_id);
% end
% [x,y]=meshgrid(k_all,d_all);
% figure
% surf(x,y,vals_J);
% xlabel('d')
% ylabel('K')
% set(gca,'FontSize',14,'ZScale','log')
% title(['Runtime (seconds): ' tools{tool_id}])
% figure
% surf(x,y,vals_relative);
% xlabel('d')
% ylabel('K')
% set(gca,'FontSize',14)
% title(['Runtime (relative): ' tools{tool_id}])
% 
% %% output into excel/csv
% csvwrite('tmp.csv',times_J*1000,2,1);
% csvwrite('tmp2.csv',times_relative,2,1);
% labels = {};
% for i=1:ntasks
%     labels{end+1} = [num2str(params{i}(1)) ',' num2str(params{i}(2)) ...
%         '->' num2str(params{i}(3))];
% end
% xlswrite('tmp.xlsx',labels')
% xlswrite('tmp.xlsx',tools,1,'B1')
% 
% %% mupad compilation
% mupad_compile_times = Inf(1,ntasks);
% mupad_compile_times(1:13) = [0.0014, 0.0019, 0.014, 0.15, 0.089,...
%     0.6, 0.5, 3.3, 4.25, 8.7, 15.1, 26, 50];
% 
% vals = zeros(numel(d_all),numel(k_all));
% for i=1:ntasks
%     d = params{i}(1);
%     k = params{i}(2);
%     vals(d_all==d,k_all==k) = mupad_compile_times(i);
% end
% [x,y]=meshgrid(k_all,d_all);
% figure
% surf(x,y,vals);
% xlabel('d')
% ylabel('K')
% set(gca,'FontSize',14,'ZScale','log')
% title('Compile time (hours): MuPAD')
% 
% figure
% x=[params{:}]; x=x(3:3:end);
% loglog(x,mupad_compile_times,'linewidth',2)
% xmax = find(~isinf(mupad_compile_times)); xmax=x(xmax(end));
% xlim([x(1) xmax])
% xlabel('# parameters')
% ylabel('compile time [hours]')
% title('Compile time (hours): MuPAD')
