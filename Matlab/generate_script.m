
%% tools

executables = {...
    'Z:\autodiff\Cpp\Test\x64\Release\Manual.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\Tapenade.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\ADOLC_split.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\ADOLC.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseRsplit\DiffSharpTest.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseR\DiffSharpTest.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseAD\DiffSharpTest.exe',...
    'python.exe Z:\autodiff\Python\PythonTests\PythonTests\PythonTests.py',...
    };

names = {...
    'J_manual',...
    'J_Tapenade_b',...
    'J_ADOLC_split',...
    'J_ADOLC',...
    'J_diffsharpRsplit',...
    'J_diffsharpR',...
    'J_diffsharpAD',...
    'J_Autograd',...
    };

nexe = numel(executables);

%% generate parameters and order them
params = {};
num_params = [];
for d = [2 10 20 32 64]
    icf_sz = d*(d + 1) / 2;
    for k = [5 10 25 50 100 200]
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
    fns{end+1} = ['Z:\autodiff\gmm_instances\gmm_d' num2str(d) '_K' num2str(k)];
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

%% write script for running AD tools

fn = 'run_experiments.bat';
fid = fopen(fn,'w');
for i=1:nexe
    for j=1:ntasks
        fprintf(fid,'START /MIN /WAIT %s %s 1\r\n',executables{i},fns{j});
    end
end
fclose(fid);

%% run experiments

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

%% read times

times_est_J = Inf(ntasks,nexe+1);
times_est_f = Inf(ntasks,nexe+1);
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
times_est_J(:,end) = times_est_adimat_J;
times_est_f(:,end) = times_est_adimat_f;

%% determine nruns for everyone

nruns = zeros(ntasks,nexe+1);
for i=1:numel(times_est_J)
    if times_est_J(i) < 5
        nruns(i) = 1000;
    elseif times_est_J(i) < 30
        nruns(i) = 100;
    elseif times_est_J(i) < 120
        nruns(i) = 10;
    elseif ~isinf(times_est_J(i))
        nruns(i) = 1;
    end
end

%% run all (adimat first)

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
times_adimat_f = Inf(1,ntasks);
times_adimat_J = Inf(1,ntasks);
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    nruns_curr = nruns(i,end);
    
    tic
    for j=1:nruns_curr
        fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
            paramsGMM.inv_cov_factors,x,hparams);
    end
    times_adimat_f(i) = toc/nruns_curr;
    
    tic
    for j=1:nruns_curr
        [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, paramsGMM.alphas,...
            paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    end
    times_adimat_J(i) = toc/nruns_curr;
    
    save('gmm_adimat_times','times_adimat_f','times_adimat_J');
end

fn = 'run_experiments_final.bat';
fid = fopen(fn,'w');
for i=1:nexe
    for j=1:ntasks
        if nruns(j,i) == 0
            continue
        end
        fprintf(fid,'START /MIN /WAIT %s %s %i\r\n',executables{i},fns{j},nruns(j,i));
    end
end
fclose(fid);

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
times_f(:,end) = ld.times_adimat_f;
times_J(:,end) = ld.times_adimat_J;

%% plot times

figure
color_order = {...
    [0    0.4470    0.7410],...
    [0.8500    0.3250    0.0980],...
    [0.9290    0.6940    0.1250],...
    [0.4940    0.1840    0.5560],...
    [0.4660    0.6740    0.1880],...
    [0.3010    0.7450    0.9330],...
    [0.6350    0.0780    0.1840],...
    'm',...
    'g',...
    };
lw = 2;
for i=1:size(times_J,2)
    semilogy(times_J(:,i),'linewidth',lw,'color',color_order{i});hold on
end
legend('manual','Tapenade\_R','ADOLC\_R\_split',...
    'ADOLC\_R','DiffSharp\_R\_split','DiffSharp\_R',...
    'DiffSharp','Autograd','AdiMat')
labels = {};
for i=1:ntasks
    labels{end+1} = [num2str(params{i}(1)) ',' num2str(params{i}(2)) ...
        '->' num2str(params{i}(3))];
end
set(gca,'xtick',1:ntasks,'xticklabel',labels,'xticklabelrotation',45,...
    'FontSize',14)
title('runtimes (seconds) - log-plot of y axis')
xlim([1 ntasks])
hold off

figure
for i=1:size(times_relative,2)
    plot(times_relative(:,i),'linewidth',lw,'color',color_order{i});hold on
end
legend('manual','Tapenade\_R','ADOLC\_R\_split',...
    'ADOLC\_R','DiffSharp\_R\_split','DiffSharp\_R',...
    'DiffSharp','Autograd','AdiMat')
set(gca,'xtick',1:ntasks,'xticklabel',labels,'xticklabelrotation',45,...
    'FontSize',14)
title('relative runtimes (seconds)')
ylim([0 100])
xlim([1 ntasks])
hold off

%% output results

times_relative = times_J./times_f;
times_relative(isnan(times_relative)) = Inf;
date = 'date';
save(['times_' date],'times_f','times_J','times_relative','params');




