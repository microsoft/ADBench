% startup
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');

% %%
% k = rand(2,1);
% x = rand(3,1);
% opt = admOptions('independents', [2]);
% 
% %%
% JforV = admDiffVFor(@foo, 1, k, x, opt)
% dy = foo_d(k,x)
% JforV - dy

%% create random GMM instance
d = 2;
k = 3;
n = 10;
n_ = 10;
rng(1);
gmm.alphas = randn(1,k);
gmm.means = au_map(@(i) rand(d,1), cell(k,1));
gmm.means = [gmm.means{:}];
gmm.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
gmm.inv_cov_factors = [gmm.inv_cov_factors{:}];
x = randn(d,n_);
hparams = [1 0];

fn = '../gmm';
% fn = '../gmm_instances/gmm_d2_K25';
save_gmm_instance([fn '.txt'],gmm,x,hparams,n);
[gmm,x,hparams] = load_gmm_instance([fn '.txt'],n~=n_);

num_params = numel(gmm.alphas) + numel(gmm.means) + ...
    numel(gmm.inv_cov_factors)

%% translate
independents = [1 2 3];
admTransform(@gmm_objective, admOptions('m', 'r','independents', independents));
admTransform(@gmm_objective, admOptions('m', 'f','independents', independents));

%% run options
nruns = 1;
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', {1});

%% external result for comparison

% Jexternal = load_J([fn '_J_manual_cpp.txt']);
% Jexternal = load_J([fn '_J_manual_eigen.txt']);
% Jexternal = load_J([fn '_J_manual_eigen_vector.txt']);
% Jexternal = load_J([fn '_J_Tapenade.txt']);
% Jexternal = load_J([fn '_J_Tapenade_split.txt']);
% Jexternal = load_J([fn '_J_ADOLC_split.txt']);
% Jexternal = load_J([fn '_J_ADOLC.txt']);
% Jexternal = load_J([fn '_J_Adept.txt']);
% Jexternal = load_J([fn '_J_Adept_split.txt']);
% Jexternal = load_J([fn '_J_Ceres.txt']);
% Jexternal = load_J([fn '_J_DiffSharp.txt']);
% Jexternal = load_J([fn '_J_DiffSharp_R.txt']);
% Jexternal = load_J([fn '_J_DiffSharp_R_split.txt']);
% Jexternal = load_J([fn '_J_Autograd.txt']);
% Jexternal = load_J([fn '_J_Autograd_split.txt']);
% Jexternal = load_J([fn '_J_Theano.txt']);
% Jexternal = load_J([fn '_J_Theano_vector.txt']);
% Jexternal = load_J([fn '_J_Julia_F.txt']);
% Jexternal = load_J([fn '_J_Julia_F_vector.txt']);
[Jrev,fvalrev] = admDiffRev(@gmm_objective_vector_repmat, 1, gmm.alphas,...
    gmm.means, gmm.inv_cov_factors, x, hparams, opt);

norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:))

%% run object function

tic
for i = 1:nruns
    fval = gmm_objective_vector_repmat(gmm.alphas,gmm.means,gmm.inv_cov_factors,x,hparams);
end
teval = toc;
teval=teval/nruns

%% run reverse mode
tic
for i = 1:nruns
    [Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, gmm.alphas,...
        gmm.means, gmm.inv_cov_factors, x, hparams, opt);
end
trev = toc;
trev=trev/nruns
%% run numerical methods for verification (finite diferences, complex variable - Lyness Moler)

tic
for i = 1:nruns
    Jfd = admDiffFD(@gmm_objective, 1, gmm.alphas,...
        gmm.means, gmm.inv_cov_factors, x, hparams, opt);
end
tFD = toc;
tFD=tFD/nruns
Jcom = admDiffComplex(@gmm_objective, 1, params.alphas,...
        params.means, params.inv_cov_factors, x, opt);

%% run Vector forward mode
tic
for i = 1:nruns
    [JforV, fvalforV] = admDiffVFor(@gmm_objective, 1, gmm.alphas,...
        gmm.means, gmm.inv_cov_factors, x, hparams, opt);
end
tforV = toc;
tforV=tforV/nruns

% compate results

% sanity check
fval-fvalrev
fval-fvalforV

% forward vs reverse
norm(Jrev(:) - JforV(:)) / norm(Jrev(:))

% AD vs numerical finite diff.
norm(Jfd(:) - Jrev(:)) / norm(Jrev(:))
norm(Jfd(:) - JforV(:)) / norm(JforV(:))

%% run forward mode
% [Jfor, fvalfor] = admDiffFor(@gmm_objective, 1, params.alphas,...
%     params.means, params.inv_cov_factors, x, opt); % translate first
% tic
% for i = 1:nruns
%     [Jfor, fvalfor] = admDiffFor(@gmm_objective, 1, params.alphas,...
%         params.means, params.inv_cov_factors, x, opt);
% end
% tfor = toc;
% tfor=tfor/nruns





%% create random BA instance
n = 2;
m = 10;
p = 10;
rng(1);
[cams,X,w,obs] = generate_random_ba_instance(n,m,p);

% num_in = numel(cams) + numel(X) + numel(w)
% num_out = 2*p + n-2 + p

fn = '../ba';
% save_ba_instance( [fn '.txt'], cams, X, w, obs )
[cams, X, w, obs] = load_ba_instance( [fn '.txt']);

%% run options
nruns = 100;%1000
non_zero_pattern = create_nonzero_pattern_ba(n,m,obs);
% differentiate only with respect to the first 2 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', ...
    {zeros(2,p) zeros(1,p)},...
    'JPattern',non_zero_pattern);
opt2 = admOptions('independents', [1 2 3],  'functionResults', ...
    {zeros(2,p) zeros(1,p)});

%%

% Jexternal = load_J_sparse([fn '_J_manual_eigen.txt']);
% Jexternal = load_J_sparse([fn '_J_Tapenade.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_eigen.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_sparse.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_sparse_eigen.txt']);
Jexternal = load_J_sparse([fn '_J_Adept.txt']);
% Jexternal = load_J_sparse([fn '_J_Ceres.txt']);
% Jexternal = load_J_sparse([fn '_J_DiffSharp.txt']);
[JforV, fvalforV1, fvalforV2] = ...
    admDiffVFor(@ba_objective, 1, cams, X, w, obs, opt);

norm(JforV(:) - Jexternal(:)) / norm(JforV(:))

%% translate

[JforV, fvalforV1, fvalforV2, fvalforV3] = ...
    admDiffVFor(@ba_objective, 1, cams, X, w, obs, opt); % translate first
[Jrev, fvalrev1, fvalrev2, fvalrev3] = ...
    admDiffRev(@ba_objective, 1, cams, X, w, obs, opt); % translate first

%% run object function
tic
for i = 1:nruns
    [fval1, fval2] = ba_objective(cams,X,w,obs);
end
teval = toc;
teval = teval/nruns

%% run Vector forward mode
tic
for i = 1:nruns
    [JforV, fvalforV1, fvalforV2, fvalforV3] = ...
        admDiffVFor(@ba_objective, 1, cams, X, w, obs, opt);
end
tforV = toc;
tforV = tforV/nruns

%% run numerical methods for verification (finite diferences, complex variable - Lyness Moler)

tic
for i = 1:nruns
    [Jfd, fvalfd1, fvalfd2, fvalfd3] = ...
        admDiffFD(@ba_objective, 1, cams, X, w, obs, opt);
end
tFD = toc;
tFD = tFD/nruns

%% run reverse mode
tic
for i = 1:nruns
    [Jrev, fvalrev1, fvalrev2, fvalrev3] = ...
        admDiffRev(@ba_objective, 1, cams, X, w, obs, opt);
end
trev = toc;
trev = trev/nruns

%% numerical method

Jcom = admDiffComplex(@ba_objective, 1, cams, X, w, obs, opt);
    
%% compate results

% sanity check
sum(abs(fval1(:)-fvalrev1(:))) +...
    sum(abs(fval2(:)-fvalrev2(:))) +...
    sum(abs(fval3(:)-fvalrev3(:)))
sum(abs(fval1(:)-fvalforV1(:))) +...
    sum(abs(fval2(:)-fvalforV2(:)))+...
    sum(abs(fval3(:)-fvalforV3(:)))

% numerical
max(abs(Jfd - Jcom))

% forward vs reverse
norm(Jrev(:) - JforV(:)) / norm(Jrev(:))

% AD vs numerical finite diff.
norm(Jfd(:) - Jrev(:)) / norm(Jrev(:))
norm(Jfd(:) - JforV(:)) / norm(JforV(:))

% AD vs numerical complex variable
% norm(Jcom(:) - Jrev(:)) / norm(Jrev(:))
% norm(Jcom(:) - JforV(:)) / norm(JforV(:))




 

%% load instance
path = '../hand';
[params, data] = load_hand_instance(path);

%% run objective
fval = hand_objective(params, data);

%%
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1],  'functionResults', {fval});

[J,fvalrev] = admDiffVFor(@hand_objective, 1, params, data, opt);

%% compare
% Jexternal = load_J([path '_J_ADOLC_eigen.txt']);
% Jexternal = load_J([path '_J_ADOLC_eigen_sparse.txt']);
Jexternal = load_J([path '_J_Ceres_eigen.txt']);
% Jexternal = load_J([path '_J_Julia_F.txt']);
norm(J(:) - Jexternal(:)) / norm(J(:))

