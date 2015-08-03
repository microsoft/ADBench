%% startup
clear all
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');


%%
% WARNING - make sure that the objective function is already translated by
% both reverse mode and forward vectorized mode

%% run options
nruns = 10;
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results

params = [  2   2    2   10    10   30    50     2   150
          100 200 1000 1000  1000 2000  2000  5000 10000 
          200 400 2000 2000  5000 5000 10000 10000 25000];
times = zeros(4,size(params,2));
niters = times;
      
tlimit_per_iter = (11*60*60)/size(params,2);
ttotal = 0;
for ip=1:size(params,2)
    
    disp(['runnning ba: ' num2str(ip)]);
    
    % generate instance
    n = params(1,ip);
    m = params(2,ip);
    p = params(3,ip);
    rng(1);
%     [cams,X,w,obs] = generate_random_ba_instance(n,m,p);
    
    fn = ['Z:\ba_instances\ba' num2str(ip)];
%     save_ba_instance([fn '.txt'],cams,X,w,obs);
    [cams, X, w, obs] = load_ba_instance( [fn '.txt']);
    
    num_in = numel(cams) + numel(X) + numel(w)
    num_out = 2*p + n-2 + p

%     cmd = ['Z:\autodiff\Cpp\Test\x64\Release\Tapenade.exe ' fn];
    cmd = ['Z:\autodiff\Cpp\Test\x64\Release\ADOLC.exe ' fn];
%     cmd = ['Z:\autodiff\Cpp\Test\x64\Release\Ceres.exe ' fn];
%     cmd = ['Z:\autodiff\Cpp\Test\x64\Release\Manual.exe ' fn];
    system(cmd);
    
% %     Jexternal = load_J_sparse([fn 'J_Tapenade_bv.txt']);
% %     Jexternal = load_J_sparse([fn 'J_Tapenade_dv.txt']);
%     Jexternal = load_J_sparse([fn 'J_ADOLC.txt']);
% %     Jexternal = load_J_sparse([fn 'J_Ceres.txt']);
% %     Jexternal = load_J_sparse([fn 'J_manual.txt']);
%     non_zero_pattern = create_nonzero_pattern(n,m,obs);
%     optPattern = admOptions('independents', [1 2 3],  'functionResults', ...
%         {zeros(2,p) zeros(1,n-2) zeros(1,p)},...
%         'JPattern',non_zero_pattern);
%     [JforV, fvalforV1, fvalforV2, fvalforV3] = ...
%         admDiffVFor(@ba_objective, 1, cams, X, w, obs, optPattern);
%     norm(Jexternal(:) - JforV(:)) / norm(JforV(:))
    
%     non_zero_pattern = create_nonzero_pattern(n,m,obs);
%     opt = admOptions('independents', [1 2 3],  'functionResults', ...
%         {zeros(2,p) zeros(1,n-2) zeros(1,p)});
%     
%     disp('runnning eval');
%     % run object function
%     tic
%     for i = 1:nruns
%         [fval1, fval2, fval3] = ba_objective(cams,X,w,obs);
%     end
%     teval = toc;
%     ttotal = ttotal + teval;
%     times(1,ip)=teval/i;
%     niters(1,ip) = i;
    
%     disp('runnning Fv');
%     % run Vector forward mode
%     tic
%     [seed_mat, coloring] = admColorSeed(non_zero_pattern);
%     for i = 1:nruns
%         [compressed_J, fvalforV1, fvalforV2, fvalforV3] = ...
%             admDiffVFor(@ba_objective, seed_mat, cams, X, w, obs, opt);
%         JforV = admUncompressJac(compressed_J, non_zero_pattern, coloring);
%         if ttotal+toc > ip*tlimit_per_iter
%             break
%         end
%     end
%     tforV = toc;
%     ttotal = ttotal + tforV;
%     times(3,ip)=tforV/i;
%     niters(3,ip) = i;
%     
%     disp('runnning FD');
%     % run numerical methods for verification (finite diferences, complex variable - Lyness Moler)
%     tic
%     [seed_mat, coloring] = admColorSeed(non_zero_pattern);
%     for i = 1:nruns
%         [compressed_J, fvalfd1, fvalfd2, fvalfd3] = ...
%             admDiffFD(@ba_objective, seed_mat, cams, X, w, obs, opt);
%         Jfd = admUncompressJac(compressed_J, non_zero_pattern, coloring);
%         if ttotal+toc > ip*tlimit_per_iter
%             break
%         end
%     end
%     tFD = toc;
%     ttotal = ttotal + tFD;
%     times(2,ip)=tFD/i;
%     niters(2,ip) = i;
    
%     disp('runnning R');
%     % run reverse mode
%     tic
%     [seed_mat, coloring] = admColorSeed(non_zero_pattern.');
%     for i = 1:nruns
%         [compressed_J, fvalrev1, fvalrev2, fvalrev3] = ...
%             admDiffRev(@ba_objective, seed_mat.', cams, X, w, obs, opt);
%         Jrev = admUncompressJac(compressed_J.', non_zero_pattern.', coloring);
%         Jrev = Jrev.';
%         if ttotal+toc > ip*tlimit_per_iter
%             break
%         end
%     end
%     trev = toc;
%     ttotal = ttotal + trev;
%     times(4,ip)=trev/i;
%     niters(4,ip) = i;
%     
%     save('adimatba.mat','times','niters','params')
% %     norm(JforV(:) - Jfd(:)) / norm(JforV(:))
%     times
end