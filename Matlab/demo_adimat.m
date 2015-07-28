%% startup
clear all
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');

%% create random GMM instance
d = 2;
k = 3;
n = 1;
rng(1);
gmm.alphas = randn(1,k);
gmm.means = au_map(@(i) rand(d,1), cell(k,1));
gmm.means = [gmm.means{:}];
gmm.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
gmm.inv_cov_factors = [gmm.inv_cov_factors{:}];
x = randn(d,n);
hparams = [1 0];

fn = 'Z:/gmm1';
% save_gmm_instance([fn '.txt'],gmm,x,hparams);
[gmm,x,hparams] = load_gmm_instance([fn '.txt']);

num_params = numel(gmm.alphas) + numel(gmm.means) + ...
    numel(gmm.inv_cov_factors)

%% run options
nruns = 1;
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', {1});

%% read external result for comparison

% Jexternal = load_J([fn 'J_Tapenade_b.txt']);
% Jexternal = load_J([fn 'J_Tapenade_dv.txt']);
% Jexternal = load_J([fn 'J_ADOLC.txt']);
Jexternal = load_J([fn 'J_Ceres.txt']);
[Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, gmm.alphas,...
    gmm.means, gmm.inv_cov_factors, x, hparams, opt);

norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:))

%% translate

[Jrev,fvalrev] = admDiffRev(@gmm_objective, 1, gmm.alphas,...
    gmm.means, gmm.inv_cov_factors, x, hparams, opt);

% [JforV, fvalforV] = admDiffVFor(@gmm_objective, 1, gmm.alphas,...
%     gmm.means, gmm.inv_cov_factors, x, opt);

%% run object function

tic
for i = 1:nruns
    fval = gmm_objective(gmm.alphas,gmm.means,gmm.inv_cov_factors,x,hparams);
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
% Jcom = admDiffComplex(@gmm_objective, 1, params.alphas,...
%         params.means, params.inv_cov_factors, x, opt);

%% run Vector forward mode
tic
for i = 1:nruns
    [JforV, fvalforV] = admDiffVFor(@gmm_objective, 1, gmm.alphas,...
        gmm.means, gmm.inv_cov_factors, x, hparams, opt);
end
tforV = toc;
tforV=tforV/nruns

%% compate results

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

num_in = numel(cams) + numel(X) + numel(w)
num_out = 2*p + n-2 + p

fn = 'Z:/ba1';
% save_ba_instance( [fn '.txt'], cams, X, w, obs )
[cams, X, w, obs] = load_ba_instance( [fn '.txt']);

%% run options
nruns = 100;%1000
non_zero_pattern = create_nonzero_pattern(n,m,obs);
% differentiate only with respect to the first 2 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', ...
    {zeros(2,p) zeros(1,n-2) zeros(1,p)},...
    'JPattern',non_zero_pattern);
opt2 = admOptions('independents', [1 2 3],  'functionResults', ...
    {zeros(2,p) zeros(1,n-2) zeros(1,p)});

%%

Jexternal = load_J_sparse([fn 'J_Tapenade_bv.txt']);
% Jexternal = load_J_sparse([fn 'J_Tapenade_dv.txt']);
% Jexternal = load_J_sparse([fn 'J_ADOLC.txt']);
% Jexternal = load_J_sparse([fn 'J_Ceres.txt']);
[JforV, fvalforV1, fvalforV2, fvalforV3] = ...
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
    [fval1, fval2, fval3] = ba_objective(cams,X,w,obs);
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

%% numerical method (finite differences)

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
% max(abs(Jfd - Jcom))

% forward vs reverse
norm(Jrev(:) - JforV(:)) / norm(Jrev(:))

% AD vs numerical finite diff.
norm(Jfd(:) - Jrev(:)) / norm(Jrev(:))
norm(Jfd(:) - JforV(:)) / norm(JforV(:))

% AD vs numerical complex variable
norm(Jcom(:) - Jrev(:)) / norm(Jrev(:))
norm(Jcom(:) - JforV(:)) / norm(JforV(:))

%% run forward mode
% [Jfor, fvalfor] = admDiffFor(@ba_objective, 1, cams, X, obs, opt); % translate first
% tic
% for i = 1:nRuns
%     [Jfor, fvalfor] = admDiffFor(@ba_objective, 1, cams, X, obs, opt);
% end
% tfor = toc


 