%% startup
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');

%% create/save/load random GMM instance
% d = 2;
% k = 3;
% n = 10;
% n_ = 10;
% rng(1);
% gmm.alphas = randn(1,k);
% gmm.means = au_map(@(i) rand(d,1), cell(k,1));
% gmm.means = [gmm.means{:}];
% gmm.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
% gmm.inv_cov_factors = [gmm.inv_cov_factors{:}];
% x = randn(d,n_);
% hparams = [1 0];

fn = '../gmm';
% fn = '../gmm_instances/gmm_d2_K25';
% save_gmm_instance([fn '.txt'],gmm,x,hparams,n);
[gmm,x,hparams] = load_gmm_instance([fn '.txt'],n~=n_);

num_params = numel(gmm.alphas) + numel(gmm.means) + ...
    numel(gmm.inv_cov_factors)

% %% only translate example - included in running admDiffRev
% independents = [1 2 3];
% admTransform(@gmm_objective, admOptions('m', 'r','independents', independents));
% admTransform(@gmm_objective, admOptions('m', 'f','independents', independents));

%% run objective
fval = gmm_objective_vector_repmat(gmm.alphas,gmm.means,gmm.inv_cov_factors,x,hparams);
%% run adimat
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', fval);
[Jrev,fvalrev] = admDiffRev(@gmm_objective_vector_repmat, 1, gmm.alphas,...
    gmm.means, gmm.inv_cov_factors, x, hparams, opt);

%% verify external result

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

norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:))

%% create/load/save random BA instance
% n = 2;
% m = 10;
% p = 10;
% rng(1);
% [cams,X,w,obs] = generate_random_ba_instance(n,m,p);

fn = '../ba';
% save_ba_instance( [fn '.txt'], cams, X, w, obs )
[cams, X, w, obs] = load_ba_instance( [fn '.txt']);

num_in = numel(cams) + numel(X) + numel(w)
num_out = 3*numel(w)

%% run objective
[fval1, fval2] = ba_objective(cams,X,w,obs);
%% run adimat - slow version - just for testing
non_zero_pattern = create_nonzero_pattern_ba(n,m,obs);
% differentiate only with respect to the first 2 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2 3],  'functionResults', ...
    {zeros(2,p) zeros(1,p)},...
    'JPattern',non_zero_pattern);
[JforV, fvalforV1, fvalforV2] = ...
    admDiffVFor(@ba_objective, 1, cams, X, w, obs, opt);

%% verify external
% Jexternal = load_J_sparse([fn '_J_manual_eigen.txt']);
% Jexternal = load_J_sparse([fn '_J_Tapenade.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_eigen.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_sparse.txt']);
% Jexternal = load_J_sparse([fn '_J_ADOLC_sparse_eigen.txt']);
% Jexternal = load_J_sparse([fn '_J_Adept.txt']);
% Jexternal = load_J_sparse([fn '_J_Ceres.txt']);
% Jexternal = load_J_sparse([fn '_J_DiffSharp.txt']);

norm(JforV(:) - Jexternal(:)) / norm(JforV(:))

%% load HAND SIMPLE instance
path = '../hand/';
model_dir = [path 'model/'];
fn = [path 'hand'];
[params, data] = load_hand_instance(model_dir,[fn '.txt']);

%% run objective
fval = hand_objective(params, data);

%% run adimat
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1],  'functionResults', {fval});

[J,fvalrev] = admDiffVFor(@hand_objective, 1, params, data, opt);

%% load HAND COMPLICATED instance
path = '../hand/';
model_dir = [path 'model/'];
fn = [path 'hand_complicated'];
[params, data, us] = load_hand_instance(model_dir,[fn '.txt']);

%% run objective
fval = hand_objective_complicated(params, us, data);

%% run adimat
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful/matlab');
% differentiate only with respect to the first+ 3 parameters
% also set the shape of function results
opt = admOptions('independents', [1 2],  'functionResults', {fval});

[J,fvalrev] = admDiffVFor(@hand_objective_complicated, 1, params, us,...
    data, opt);
% compress
J = [sum(J(:,27:2:end),2) sum(J(:,28:2:end),2) J(:,1:26)];
%% compare external
% Jexternal = load_J([fn '_J_Manual_eigen.txt']);
% Jexternal = load_J([fn '_J_ADOLC_eigen.txt']);
% Jexternal = load_J([fn '_J_ADOLC_eigen_tapeless.txt']);
% Jexternal = load_J([fn '_J_ADOLC_light.txt']);
% Jexternal = load_J([fn '_J_ADOLC_light_tapeless.txt']);
% Jexternal = load_J([fn '_J_Adept_light.txt']);
% Jexternal = load_J([fn '_J_Ceres_eigen.txt']);
% Jexternal = load_J([fn '_J_Ceres_light.txt']);
% Jexternal = load_J([fn '_J_Julia_F.txt']);
% Jexternal = load_J([fn '_J_DiffSharp.txt']);
% Jexternal = load_J([fn '_J_DiffSharp_F.txt']);
% Jexternal = load_J([fn '_J_Theano.txt']);
% Jexternal = load_J([fn '_J_Theano_rop.txt']);

norm(J(:) - Jexternal(:)) / norm(J(:))

