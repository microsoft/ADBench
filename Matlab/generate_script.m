
%% tools

executables = {...
    'Z:\autodiff\Cpp\Test\x64\Release\Manual.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\Tapenade.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\ADOLC_split.exe',...
    'Z:\autodiff\Cpp\Test\x64\Release\ADOLC.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseRsplit\DiffSharpTest.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseR\DiffSharpTest.exe',...
    'Z:\autodiff\Fsharp\Tests\DiffSharp\bin\ReleaseAD\DiffSharpTest.exe'};

names = {...
    'J_manual',...
    'J_Tapenade_b',...
    'J_ADOLC_split',...
    'J_ADOLC',...
    'J_diffsharpRsplit',...
    'J_diffsharpR',...
    'J_diffsharpAD'};

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
