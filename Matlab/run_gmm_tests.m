%% startup
clear all
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');


%%
% WARNING - make sure that the objective function is already translated by
% both reverse mode and forward vectorized mode

%% run options
nruns = 1000;
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
opt2 = admOptions('independents', [1 2 3],  'functionResults', {1},'fdMode','central');

params = [  2     2   2     2    2     2    2   10   20   10
            3     3  10    10   25    25   50    5    5   25
          100 10000 500 10000 1000 10000 1000 1000 1000 2500];
times = zeros(4,size(params,2));
niters = times;
      
tlimit_per_iter = (13*60*60)/size(params,2); % 6 hours limit in total
ttotal = 0;
for ip=1:size(params,2)
    
    disp(['runnning gmm: ' num2str(ip)]);
    
    % generate instance
    d = params(1,ip);
    k = params(2,ip);
    n = params(3,ip);
%     rng(1);
%     paramsGMM.alphas = randn(1,k);
%     paramsGMM.means = au_map(@(i) rand(d,1), cell(k,1));
%     paramsGMM.means = [paramsGMM.means{:}];
%     paramsGMM.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
%     paramsGMM.inv_cov_factors = [paramsGMM.inv_cov_factors{:}];
%     x = randn(d,n);
%     hparams = [1 0];
    
    fn = ['Z:\gmm_instances\gmm' num2str(ip)];
%     save_gmm_instance([fn '.txt'],paramsGMM,x,hparams);
    [paramsGMM,x,hparams] = load_gmm_instance([fn '.txt']);
    
    num_params = numel(paramsGMM.alphas) + numel(paramsGMM.means) + ...
        numel(paramsGMM.inv_cov_factors)
    
%     cmd = ['Z:\C\Test\x64\Release\Tapenade.exe ' fn];
%     cmd = ['Z:\C\Test\x64\Release\ADOLC.exe ' fn];
    cmd = ['Z:\C\Test\x64\Release\Ceres.exe ' fn];
    system(cmd);
    
%     Jexternal = load_J([fn 'J_Tapenade_b.txt']);
%     Jexternal = load_J([fn 'J_Tapenade_dv.txt']);
%     Jexternal = load_J([fn 'J_ADOLC.txt']);
    Jexternal = load_J([fn 'J_Ceres.txt']);
    [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, paramsGMM.alphas,...
            paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    norm(Jexternal(:) - Jrev(:)) / norm(Jrev(:))

%     disp('runnning eval');
%     
%     % run object function
%     tic
%     for i = 1:nruns
%         fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
%             paramsGMM.inv_cov_factors,x,hparams);
%     end
%     teval = toc;
%     ttotal = ttotal + teval;
%     times(1,ip)=teval/i;
%     niters(1,ip) = i;
%     
%     disp('runnning R');
%     
%     % run reverse mode
%     tic
%     for i = 1:nruns
%         [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, paramsGMM.alphas,...
%             paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
%         if ttotal+toc > ip*tlimit_per_iter
%             break
%         end
%     end
%     trev = toc;
%     ttotal = ttotal + trev;
%     times(4,ip)=trev/i;
%     niters(4,ip) = i;
%     
%     disp('runnning FD');
%     
%     % run numerical methods for verification (finite diferences, complex variable - Lyness Moler)
%     tic
%     for i = 1:nruns
%         Jfd = admDiffFD(@gmm_objective, 1, paramsGMM.alphas,...
%             paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
%         if ttotal+toc > ip*tlimit_per_iter
%             break
%         end
%     end
%     tFD = toc;
%     ttotal = ttotal + tFD;
%     times(2,ip)=tFD/i;
%     niters(2,ip) = i;
%     
% %     disp('runnning Fv');
% %     
% %     % run Vector forward mode
% %     tic
% %     for i = 1:nruns
% %         [JforV, fvalforV] = admDiffVFor(@gmm_objective, 1, paramsGMM.alphas,...
% %             paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
% %         if ttotal+toc > ip*tlimit_per_iter
% %             break
% %         end
% %     end
% %     tforV = toc;
% %     ttotal = ttotal + tforV;
% %     times(3,ip)=tforV/i;
% %     niters(3,ip) = i;
%     
%     save('adimatgmm.mat','times','niters','params')
end
