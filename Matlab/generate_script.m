%% get tools
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release/';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python/';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/gmm_instances/';
% data_dir = 'C:/Users/t-filsra/Workspace/autodiff/gmm_instances/10k/';
% npoints = 10000;

tools = get_tools(exe_dir,python_dir);
manual_cpp_id = 1;
ntools = numel(tools);

%% generate parameters and order them
d_all = [2 10 20 32 64];
k_all = [5 10 25 50 100 200];
params = {};
num_params = [];
for d = d_all
    icf_sz = d*(d + 1) / 2;
    for k = k_all
        num_params(end+1) = k + d*k + icf_sz*k;
        params{end+1} = [d k num_params(end)];
    end
end

[num_params, order] = sort(num_params);
params = params(order);
% ignore = [2 3 4 5 8 10];
% params = params(~ismember(1:numel(params),ignore));
for i=1:numel(params)
    disp(num2str(params{i}));
end

fns = {};
for i=1:numel(params)
    d = params{i}(1);
    k = params{i}(2);
    fns{end+1} = [data_dir 'gmm_d' num2str(d) '_K' num2str(k)];
end
ntasks = numel(params);
% save('params_gmm.mat','params');

%% write instances into files
addpath('awful/matlab')
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    
    d = params{i}(1);
    k = params{i}(2);
    
    rng(1);
    paramsGMM.alphas = randn(1,k);
    paramsGMM.means = au_map(@(i) rand(d,1), cell(k,1));
    paramsGMM.means = [paramsGMM.means{:}];
    paramsGMM.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
    paramsGMM.inv_cov_factors = [paramsGMM.inv_cov_factors{:}];
    x = randn(d,npoints);
    hparams = [1 0];
    
    save_gmm_instance([fns{i} '.txt'], paramsGMM, x, hparams);
end

%% write script for running tools once
fn_run_once = 'run_tools_once.bat';
fid = fopen(fn_run_once,'w');
for i=1:ntools
    if tools(i).call_type < 3
        if tools(i).call_type == 1 % theano
            cmd = ['START /MIN /WAIT ' tools(i).run_cmd];
            for j=1:ntasks
                cmd = [cmd ' ' fns{j} ' 1 1'];
            end
            fprintf(fid,[cmd '\r\n']);
        else
            for j=1:ntasks
                if tools(i).call_type == 0 % standard run
                    fprintf(fid,'START /MIN /WAIT %s %s 1 1\r\n',tools(i).run_cmd,fns{j});
                elseif tools(i).call_type == 2 % ceres
                    d = params{j}(1);
                    k = params{j}(2);
                    fprintf(fid,'START /MIN /WAIT %sd%ik%i.exe %s 1 1\r\n',...
                        tools(i).run_cmd,d,k,fns{j});
                end
            end
        end            
    end
end
fclose(fid);

%% run all tools once - runtimes estimates
% tic
% system(fn_run_once);
% toc

% tools ran from matlab
nruns = ones(1,ntasks);
for i=1:ntools
   J_file = [data_dir 'J_' tools(i).ext '.mat'];
   times_file = [data_dir 'times_est_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_vector = false;
       adimat_run_gmm_tests(do_adimat_vector,params,fns,...
           nruns,nruns,J_file,times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_vector = true;
       adimat_run_gmm_tests(do_adimat_vector,params,fns,...
           nruns,nruns,J_file,times_file);
   elseif tools(i).call_type == 5 % mupad
       mupad_run_gmm_tests(params,fns,...
           nruns,nruns,times_file);
   end    
end

%% read time estimates & determine nruns for everyone
times_est_J = Inf(ntasks,ntools);
times_est_f = Inf(ntasks,ntools);
up_to_date_mask = false(ntasks,ntools);
for i=1:ntools
    if tools(i).call_type < 3
        for j=1:ntasks
            fn = [fns{j} tools(i).ext '_times.txt'];
            if exist(fn,'file')
                fid = fopen(fn);
                times_est_f(j,i) = fscanf(fid,'%lf',1);
                times_est_J(j,i) = fscanf(fid,'%lf',1);
                fclose(fid);
            end
            up_to_date_mask(j,i) = is_up_to_date(fn,tools(i).exe);
        end
    elseif tools(i).call_type >= 3
        fn = [data_dir 'times_' tools(i).ext '.mat'];
        if ~exist(fn,'file')
            fn = [data_dir 'times_est_' tools(i).ext '.mat'];
        end
        if exist(fn,'file')
            ld=load(fn);
            times_est_f(:,i) = ld.times_f;
            times_est_J(:,i) = ld.times_J;
        end
        up_to_date_mask(:,i) = is_up_to_date(fn,tools(i).exe);
    end
end

nruns_f = determine_n_runs(times_est_f) .* ~up_to_date_mask;
nruns_J = determine_n_runs(times_est_J) .* ~up_to_date_mask;

%% write script for running tools
fn_run_experiments = 'run_experiments.bat';
fid = fopen(fn_run_experiments,'w');
for i=1:ntools
    if tools(i).call_type < 3
        if tools(i).call_type == 1 && sum(nruns_f(:,i) + nruns_J(:,i))>0% theano
            cmd = ['START /MIN /WAIT ' tools(i).run_cmd];
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    cmd = [cmd ' ' fns{j} ' '...
                        num2str(nruns_f(j,i)) ' ' num2str(nruns_J(j,i))];
                end
            end
            fprintf(fid,[cmd '\r\n']);
        else
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    if tools(i).call_type == 0 % standard run
                        fprintf(fid,'START /MIN /WAIT %s %s %i %i\r\n',...
                            tools(i).run_cmd,fns{j},...
                            nruns_f(j,i),nruns_J(j,i));
                    elseif tools(i).call_type == 2 % ceres
                        d = params{j}(1);
                        k = params{j}(2);
                        fprintf(fid,'START /MIN /WAIT %sd%ik%i.exe %s %i %i\r\n',...
                            tools(i).run_cmd,d,k,fns{j},...
                            nruns_f(j,i),nruns_J(j,i));
                    end
                end
            end
        end            
    end
end
fclose(fid);

%% run all experiments
tic
system(fn_run_experiments);
toc

% tools ran from matlab
for i=1:ntools
   J_file = [data_dir 'J_' tools(i).ext '.mat'];
   times_file = [data_dir 'times_' tools(i).ext '.mat'];
   if tools(i).call_type == 3 % adimat
       do_adimat_vector = false;
       adimat_run_gmm_tests(do_adimat_vector,params,fns,...
           nruns_f(:,i),nruns_J(:,i),J_file,times_file);
   elseif tools(i).call_type == 4 % adimat vector
       do_adimat_vector = true;
       adimat_run_gmm_tests(do_adimat_vector,params,fns,...
           nruns_f(:,i),nruns_J(:,i),J_file,times_file);
   elseif tools(i).call_type == 5 % mupad
       mupad_run_gmm_tests(params,fns,...
           nruns_f(:,i),nruns_J(:,i),times_file);
   end    
end

%% verify results (except mupad and adimats)
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
bad = {};
num_ok = 0;
num_not_comp = 0;
for i=1:ntasks
    disp(['comparing to adimat: gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    [Jrev,fvalrev] = admDiffRev(@gmm_objective_vector_repmat, 1, paramsGMM.alphas,...
        paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    
    for j=1:ntools
        if tools(j).call_type < 3
            fn = [fns{i} names{j} '.txt'];
            if exist(fn,'file')
                Jexternal = load_J(fn);
                tmp = norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:));
                if tmp < 1e-5
                    num_ok = num_ok + 1;
                else
                    bad{end+1} = {fn, tmp};
                end
            else
                disp([names{j} ': not computed']);
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

%% read final times
times_f = Inf(ntasks,ntools);
times_J = Inf(ntasks,ntools);
for i=1:ntools
    if tools(i).call_type < 3
        for j=1:ntasks
            fn = [fns{j} tools(i).ext '_times.txt'];
            if exist(fn,'file') && is_up_to_date(fn,tools(i).exe)
                fid = fopen(fn);
                times_f(j,i) = fscanf(fid,'%lf',1);
                times_J(j,i) = fscanf(fid,'%lf',1);
                fclose(fid);
            end
        end
    elseif tools(i).call_type >= 3
        fn = [data_dir 'times_' tools(i).ext '.mat'];
        if exist(fn,'file') && is_up_to_date(fn,tools(i).exe)
            ld=load(fn);
            times_f(:,i) = ld.times_f;
            times_J(:,i) = ld.times_J;
        end
    end
end

times_f_relative = bsxfun(@rdivide,times_f,times_f(:,manual_cpp_id));
times_f_relative(isnan(times_f_relative)) = Inf;
times_f_relative(times_f_relative==0) = Inf;
% times_relative = times_J./times_f;
times_J_relative = bsxfun(@rdivide,times_J,times_J(:,manual_cpp_id));
times_J_relative(isnan(times_J_relative)) = Inf;
times_J_relative(times_J_relative==0) = Inf;

%% output results
save([data_dir 'times_' date],'times_f','times_J','params','tools');

%% plot times
lw = 2;
msz = 7;
x=[params{:}]; x=x(3:3:end);

plot_log_runtimes(params,tools,times_J,...
    'Jacobian runtimes','runtime [seconds]');

plot_log_runtimes(params,tools,times_J_relative,...
    'Jacobian runtimes relative to Manual, C++','runtime');

plot_log_runtimes(params,tools,times_f,...
    'objective runtimes','runtime [seconds]');

plot_log_runtimes(params,tools,times_f_relative,...
    'objective runtimes relative to Manual, C++','runtime');

%% do 2D plots
tool_id = adimat_id-1;
vals_J = zeros(numel(d_all),numel(k_all));
vals_relative = vals_J;
for i=1:ntasks
    d = params{i}(1);
    k = params{i}(2);
    vals_relative(d_all==d,k_all==k) = times_relative(i,tool_id);
    vals_J(d_all==d,k_all==k) = times_J(i,tool_id);
end
[x,y]=meshgrid(k_all,d_all);
figure
surf(x,y,vals_J);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14,'ZScale','log')
title(['Runtime (seconds): ' tools{tool_id}])
figure
surf(x,y,vals_relative);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14)
title(['Runtime (relative): ' tools{tool_id}])

%% output into excel/csv
csvwrite('tmp.csv',times_J*1000,2,1);
csvwrite('tmp2.csv',times_relative,2,1);
labels = {};
for i=1:ntasks
    labels{end+1} = [num2str(params{i}(1)) ',' num2str(params{i}(2)) ...
        '->' num2str(params{i}(3))];
end
xlswrite('tmp.xlsx',labels')
xlswrite('tmp.xlsx',tools,1,'B1')

%% mupad compilation
mupad_compile_times = Inf(1,ntasks);
mupad_compile_times(1:13) = [0.0014, 0.0019, 0.014, 0.15, 0.089,...
    0.6, 0.5, 3.3, 4.25, 8.7, 15.1, 26, 50];

vals = zeros(numel(d_all),numel(k_all));
for i=1:ntasks
    d = params{i}(1);
    k = params{i}(2);
    vals(d_all==d,k_all==k) = mupad_compile_times(i);
end
[x,y]=meshgrid(k_all,d_all);
figure
surf(x,y,vals);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14,'ZScale','log')
title('Compile time (hours): MuPAD')

figure
x=[params{:}]; x=x(3:3:end);
loglog(x,mupad_compile_times,'linewidth',2)
xmax = find(~isinf(mupad_compile_times)); xmax=x(xmax(end));
xlim([x(1) xmax])
xlabel('# parameters')
ylabel('compile time [hours]')
title('Compile time (hours): MuPAD')

% %% Transport objective runtimes
% fromID = 10;
% toID = 9;
% for i=1:ntasks
%     fnFrom = [fns{i} names{fromID} '_times.txt'];
%     fnTo = [fns{i} names{toID} '_times.txt'];
%     if exist(fnFrom,'file') && exist(fnTo,'file')
%         fid = fopen(fnFrom);
%         time_f_from = fscanf(fid,'%lf',1);
%         fclose(fid);
%         fid = fopen(fnTo,'r');
%         time_f_to = fscanf(fid,'%lf',1);
%         time_J_to = fscanf(fid,'%lf',1);
%         fclose(fid);
%         fid = fopen(fnTo,'w');
%         fprintf(fid,'%f %f %f\n',time_f_from,time_J_to,time_J_to/time_f_from);
%         fprintf(fid,'tf tJ tJ/tf');
%         fclose(fid);
%     end
% end
