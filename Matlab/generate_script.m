%%
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/gmm_instances';

%% tools
executables = {...
    fullfile(exe_dir,'Manual_Eigen.exe'),...
    fullfile(exe_dir,'Manual_VS.exe'),...
    fullfile(exe_dir,'Tapenade.exe'),...
    fullfile(exe_dir,'ADOLC_split.exe'),...
    fullfile(exe_dir,'ADOLC_full.exe'),...
    fullfile(exe_dir,'ReleaseRSplit/DiffSharp.exe.exe'),...
    fullfile(exe_dir,'ReleaseR/DiffSharp.exe.exe'),...
    fullfile(exe_dir,'ReleaseAD/DiffSharp.exe.exe'),...
    ['python.exe ' fullfile(python_dir,'Autograd/autograd_split.py')],...
    ['python.exe ' fullfile(python_dir,'Autograd/autograd.py')],...
    ['python.exe ' fullfile(python_dir,'Theano/Theano.py')],...
    fullfile(exe_dir,'Adept.exe'),...
    };
names = {...
    'J_manual',...
    'J_manual_VS',...
    'J_Tapenade_b',...
    'J_ADOLC_split',...
    'J_ADOLC',...
    'J_diffsharpRsplit',...
    'J_diffsharpR',...
    'J_diffsharpAD',...
    'J_Autograd_split',...
    'J_Autograd',...
    'J_Theano',...
    'J_Adept',...
    };
% executables = {...
%     fullfile(exe_dir,'Manual_Eigen.exe'),...
%     fullfile(exe_dir,'Manual_Eigen2.exe'),...
%     fullfile(exe_dir,'Manual_Eigen3.exe'),...
%     fullfile(exe_dir,'Manual_Eigen4.exe'),...
%     fullfile(exe_dir,'Manual_Eigen5.exe'),...
%     fullfile(exe_dir,'Manual_VS.exe'),...
%     };
% names = {...
%     'J_manual',...
%     'J_manual_Eigen2',...
%     'J_manual_Eigen3',...
%     'J_manual_Eigen4',...
%     'J_manual_Eigen5',...
%     'J_manual_VS',...
%     };
nexe = numel(executables);
tools = {...
    'manual\_Eigen',...
    'manual\_Cpp',...
    'Tapenade\_R',...
    'ADOLC\_R\_split',...
    'ADOLC\_R',...
    'DiffSharp\_R\_split',...
    'DiffSharp\_R',...
    'DiffSharp',...
    'Autograd\_R\_split',...
    'Autograd\_R',...
    'Theano',...
    'Adept\_R',...
    'AdiMat\_R',...
    'MuPAD'...
    };
% tools = {...
%     'manual\_Eigen',...
%     'manual\_Eigen2',...
%     'manual\_Eigen3',...
%     'manual\_Eigen4',...
%     'manual\_Eigen5',...
%     'manual\_Cpp',...
%     'AdiMat\_R',...
%     'MuPAD'...
%     };
ntools = numel(tools);
adimat_id = ntools-1;
mupad_id = ntools;

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
    fns{end+1} = fullfile(data_dir, ['gmm_d' num2str(d) '_K' num2str(k)]);
end
ntasks = numel(params);
% save('params_gmm.mat','params');

%% write instances into files
fns = {};
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    
    d = params{i}(1);
    k = params{i}(2);
    n = 1000;
    
    rng(1);
    paramsGMM.alphas = randn(1,k);
    paramsGMM.means = au_map(@(i) rand(d,1), cell(k,1));
    paramsGMM.means = [paramsGMM.means{:}];
    paramsGMM.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
    paramsGMM.inv_cov_factors = [paramsGMM.inv_cov_factors{:}];
    x = randn(d,n);
    hparams = [1 0];
    
    save_gmm_instance([fns{end} '.txt'], paramsGMM, x, hparams);
end

%% write script for running AD tools once
fn = 'run_experiments.bat';
fid = fopen(fn,'w');
for i=1:nexe
    if strcmp('Theano',tools{i}(1:6))
%         cmd = ['START /MIN /WAIT ' executables{i}];
%         for j=1:ntasks
%             cmd = [cmd ' ' fns{j} ' 1'];
%         end
%         fprintf(fid,[cmd '\r\n']);
    else
        for j=1:ntasks
            fprintf(fid,'START /MIN /WAIT %s %s 1\r\n',executables{i},fns{j});
        end
    end
end
fclose(fid);

%% run experiments for time estimates
tic
system(fn);
toc

%% adimat time estimate
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
times_est_adimat_f = Inf(1,ntasks);
times_est_adimat_J = Inf(1,ntasks);
admTransform(@gmm_objective, admOptions('m', 'r','independents', [1 2 3]));
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    tic
    fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
        paramsGMM.inv_cov_factors,x,hparams);
    times_est_adimat_f(i) = toc;
    
    tic
    [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, paramsGMM.alphas,...
            paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    times_est_adimat_J(i) = toc;
end

%% read time estimates
times_est_J = Inf(ntasks,ntools);
times_est_f = Inf(ntasks,ntools);
for i=1:ntasks
    for j=1:nexe
        fn = [fns{i} names{j} '_times.txt'];
        if exist(fn,'file')
            fid = fopen(fn);
            times_est_f(i,j) = fscanf(fid,'%lf',1);
            times_est_J(i,j) = fscanf(fid,'%lf',1);
            fclose(fid);
        end
    end
end
times_est_J(:,adimat_id) = times_est_adimat_J;
times_est_f(:,adimat_id) = times_est_adimat_f;

%% determine nruns for everyone
nruns_J = zeros(ntasks,ntools);
for i=1:numel(times_est_J)
    if times_est_J(i) < 5
        nruns_J(i) = 1000;
    elseif times_est_J(i) < 30
        nruns_J(i) = 100;
    elseif times_est_J(i) < 120
        nruns_J(i) = 10;
    elseif ~isinf(times_est_J(i))
%         nruns(i) = 1; 
        nruns_J(i) = 0; % it has already ran once
    end
end
nruns_f = zeros(ntasks,ntools);
for i=1:numel(times_est_f)
    if times_est_f(i) < 5
        nruns_f(i) = 1000;
    elseif times_est_f(i) < 30
        nruns_f(i) = 100;
    elseif times_est_f(i) < 120
        nruns_f(i) = 10;
    elseif ~isinf(times_est_f(i))
%         nruns(i) = 1; 
        nruns_f(i) = 0; % it has already ran once
    end
end

%% run adimat all
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
times_adimat_f = Inf(1,ntasks);
times_adimat_J = Inf(1,ntasks);
times_adimat_J___ = Inf(1,ntasks);
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    nruns_curr_f = nruns_f(i,adimat_id);
    nruns_curr_J = nruns_J(i,adimat_id);
    
    tic
    for j=1:nruns_curr_f
        fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
            paramsGMM.inv_cov_factors,x,hparams);
    end
    times_adimat_f(i) = toc/nruns_curr_f;
    
    tic
    for j=1:nruns_curr_J
        do_F_mode = false;
        [J, fvalrev] = gmm_objective_adimat(do_F_mode,paramsGMM.alphas,...
            paramsGMM.means,paramsGMM.inv_cov_factors,x,hparams);
    end
    times_adimat_J(i) = toc/nruns_curr_J;
    
%     save('gmm_adimat_times','times_adimat_f','times_adimat_J');
end

%% run mupad
addpath('awful\matlab');
times_mupad_f = Inf(1,ntasks);
times_mupad_J = Inf(1,ntasks);
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    nruns_curr = 1000;
    
    tic
    [ J, err ] = gmm_objective_d_symbolic(nruns_curr, paramsGMM, x, ...
        hparams, false);
    if ~isempty(J)
        times_mupad_f(i) = toc/nruns_curr;
    end
    
    tic
    [ J, err ] = gmm_objective_d_symbolic(nruns_curr, paramsGMM, x,...
        hparams, true);
    
    if ~isempty(J)
        times_mupad_J(i) = toc/nruns_curr;
    end
    
%     save('gmm_mupad_times','times_mupad_f','times_mupad_J');
end

%% generate script for others
fn = 'run_experiments_final.bat';
fid = fopen(fn,'w');
for i=1:nexe
    if strcmp('Theano',tools{i}(1:6))
%         cmd = ['START /MIN /WAIT ' executables{i}];
%         for j=1:ntasks
%             if nruns(j,i) > 0
%                 cmd = [cmd ' ' fns{j} ' ' num2str(nruns(j,i))];
%             end
%         end
%         fprintf(fid,[cmd '\r\n']);
    else
        for j=1:ntasks
            if nruns_J(j,i) == 0
                continue
            end
            fprintf(fid,'START /MIN /WAIT %s %s %i %i\r\n',...
                executables{i},fns{j},nruns_f(j,i),nruns_J(j,i));
        end
    end
end
fclose(fid);

%% run others
tic
system(fn);
toc

%% verify results
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
    [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, paramsGMM.alphas,...
        paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    
    for j=1:nexe
        fn = [fns{i} names{j} '.txt'];
        if exist(fn,'file')
            Jexternal = load_J(fn);
            tmp = norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:));
%             disp([names{j} ': ' num2str(tmp)]);
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
disp(['num ok: ' num2str(num_ok)]);
disp(['num bad: ' num2str(numel(bad))]);
disp(['num not computed: ' num2str(num_not_comp)]);
for i=1:numel(bad)
    disp([bad{i}{1} ' : ' num2str(bad{i}{2})]);
end

%% read final times
times_f = Inf(ntasks,nexe+1);
times_J = Inf(ntasks,nexe+1);
for i=1:ntasks
    for j=1:nexe
        fn = [fns{i} names{j} '_times.txt'];
        if exist(fn,'file')
            fid = fopen(fn);
            times_f(i,j) = fscanf(fid,'%lf',1);
            times_J(i,j) = fscanf(fid,'%lf',1);
            fclose(fid);
        end
    end
end
ld = load('gmm_adimat_times');
times_f(:,adimat_id) = ld.times_adimat_f;
times_J(:,adimat_id) = ld.times_adimat_J;
ld = load('gmm_mupad_times');
times_f(:,mupad_id) = ld.times_mupad_f;
times_J(:,mupad_id) = ld.times_mupad_J;

times_relative = times_J./times_f;
times_relative(isnan(times_relative)) = Inf;
times_relative(times_relative==0) = Inf;

%% output results
save(['times_' date],'times_f','times_J','times_relative','params','tools');

%% plot times
set(groot,'defaultAxesColorOrder',...
    [.8 .1 0;0 .7 0;.2 .2 1; 0 0 0; .8 .8 0],...
    'defaultAxesLineStyleOrder', '-|s-|x-')
lw = 2;
msz = 7;
% order = fliplr([2 12 11 1 3 5 4 6 7 8 9 10]);
order = fliplr([7 5 3 6 8 2 4 1]);
% order = 1:ntools;
x=[params{:}]; x=x(3:3:end);

% % Runtime
% figure
% loglog(x, times_J(:, order),'linewidth',lw,'markersize',msz);
% legend({tools{order}}, 'location', 'se');
% set(gca,'FontSize',14)
% xlim([min(x) max(x)])
% title('runtimes (seconds)')
% xlabel('# parameters')
% ylabel('runtime [seconds]')
% 
% % Relative
% figure
% loglog(x, times_relative(:, order),'linewidth',lw,'markersize',msz);
% legend({tools{order}}, 'location', 'nw');
% set(gca,'FontSize',14)
% xlim([min(x) max(x)])
% title('relative runtimes')
% xlabel('# parameters')
% ylabel('relative runtime')

% Objective function
figure
loglog(x, times_f(:, order),'linewidth',lw,'markersize',msz);
legend({tools{order}}, 'location', 'se');
set(gca,'FontSize',14)
xlim([min(x) max(x)])
title('objective runtimes (seconds)')
xlabel('# parameters')
ylabel('runtime [seconds]')

%% do 2D plots
tool_id = 11;
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
