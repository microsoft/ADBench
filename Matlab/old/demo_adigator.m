%% startup
clear all
addpath('adigator');
startupadigator
addpath('awful\matlab')

%% translate
% variable of differentiation
d = 2;
k = 4;
params.alphas = adigatorCreateDerivInput([1 k],'params.alphas');
params.means = adigatorCreateDerivInput([d k],'params.means');
params.inv_cov_factors = adigatorCreateDerivInput([(d*(d+1)/2) k],'params.inv_cov_factors');

% unknown auxiliary variables
x = adigatorCreateAuxInput([d 1]);

% fixed value axiliary variables
% -

% create derivative code
adigator('gmm_objective_adigator',{params,x},'gmm_objective_adigator_d');

%% prepare for run - create random instance (fields must be named .f and .dVARNAME)
rng(1);
params.alphas = struct('f',randn(1,k),'dparams',struct('alphas',ones(1,k)));
means = au_map(@(i) rand(d,1), cell(k,1));
params.means = struct('f',[means{:}],'dparams',struct('means',ones(d,k)));
inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
params.inv_cov_factors = struct('f',[inv_cov_factors{:}],'dparams',...
    struct('inv_cov_factors',ones((d*(d+1)/2),k)));
x = randn(d,1);

%% evaluate
err = gmm_objective_adigator_d(params, x);

% function value
err.f

% check function value with correct one (print difference)
params2.alphas = params.alphas.f;
params2.means = params.means.f;
params2.inv_cov_factors = params.inv_cov_factors.f;
err.f - gmm_objective_adigator(params2, x)

% derivatives
err.dparams.alphas
err.dparams.means
err.dparams.inv_cov_factors