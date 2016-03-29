% This code was generated using ADiGator version 1.1
% ©2010-2014 Matthew J. Weinstein and Anil V. Rao
% ADiGator may be obtained at https://sourceforge.net/projects/adigator/ 
% Contact: mweinstein@ufl.edu
% Bugs/suggestions may be reported to the sourceforge forums
%                    DISCLAIMER
% ADiGator is a general-purpose software distributed under the GNU General
% Public License version 3.0. While the software is distributed with the
% hope that it will be useful, both the software and generated code are
% provided 'AS IS' with NO WARRANTIES OF ANY KIND and no merchantability
% or fitness for any purpose or application.

function err = gmm_objective_adigator_d(params,x)
global ADiGator_gmm_objective_adigator_d
if isempty(ADiGator_gmm_objective_adigator_d); ADiGator_LoadData(); end
Gator1Data = ADiGator_gmm_objective_adigator_d.gmm_objective_adigator_d.Gator1Data;
% ADiGator Start Derivative Computations
%User Line: % GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%User Line: %         First argument PARAMS stores GMM
%User Line: %             params.log_alphas
%User Line: %                1 x k vector of logs of mixture weights (unnormalized), so
%User Line: %                weights = exp(log_alphas)/sum(exp(log_alphas))
%User Line: %             params.means
%User Line: %                d x k matrix of component means
%User Line: %             params.inv_cov_factors
%User Line: %                (d*(d+1)/2) x k matrix, parametrizing
%User Line: %                lower triangular square roots of inverse covariances
%User Line: %                log of diagonal is first d params
%User Line: %         Second argument X is a data point (dx1 vector)
%User Line: %      To generate params given covariance C:
%User Line: %           L = inv(chol(C,'lower'));
%User Line: %           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]
%User Line: %      This will be mexed by au_ccode, so doesn't need to be super fast.
d.f = size(x,1);
%User Line: d = size(x,1);
k.f = size(params.alphas.f,2);
%User Line: k = size(params.alphas,2);
alphas.dparams.alphas = params.alphas.dparams.alphas; alphas.f = params.alphas.f;
%User Line: alphas = params.alphas;
means.dparams.means = params.means.dparams.means; means.f = params.means.f;
%User Line: means = params.means;
%User Line: % lower_triangle_indices = my_tril(ones(d,d), -1) ~= 0;
%User Line: %
%User Line: % lse = zeros(k,1);
%User Line: % for ik=1:k
%User Line: %     % Unpack L parameters into d*d matrix.
%User Line: %     Lparams = params.inv_cov_factors(:,ik);
%User Line: %     % Set L's diagonal
%User Line: %     logLdiag = Lparams(1:d);
%User Line: %     L = diag(exp(logLdiag));
%User Line: %     % And set lower triangle
%User Line: %     L(lower_triangle_indices) = Lparams(d+1:end);
%User Line: %
%User Line: %     mahal = L'*(means(:,ik) - x);
%User Line: %     lse(ik) = alphas(ik) + sum(logLdiag) - 0.5*(mahal'*mahal);
%User Line: % end
cada1f1 = 2.506628274631^d.f;
constant.f = 1/cada1f1;
%User Line: constant = 1 / sqrt(2*pi)^d;
err.f = log(constant.f);
%User Line: err = log(constant);
%User Line: % err = err + logsumexp(lse);
cadainput2_1.dparams.alphas = alphas.dparams.alphas; cadainput2_1.f = alphas.f;
%User Line: cadainput2_1 = alphas;
cadaoutput2_1 = ADiGator_logsumexp1(cadainput2_1);
% Call to function: logsumexp
err.dparams.alphas = -cadaoutput2_1.dparams.alphas;
err.f = err.f - cadaoutput2_1.f;
%User Line: err = err - cadaoutput2_1;
%User Line: % err = log(constant) + log(sum(exp(lse))) - log(sum(exp(alphas)));
err.dparams.alphas_size = 4;
err.dparams.alphas_location = Gator1Data.Index1;
end
function out = ADiGator_logsumexp1(x)
global ADiGator_gmm_objective_adigator_d
Gator1Data = ADiGator_gmm_objective_adigator_d.ADiGator_logsumexp1.Gator1Data;
% ADiGator Start Derivative Computations
%User Line: % LOGSUMEXP  Compute log(sum(exp(x))) stably.
%User Line: %               x is a vector
cada1tf1 = max(x.f,[],2);
cada1tf2 = (x.f == cada1tf1).';
mx.f = cada1tf1;
cada1td1 = zeros(4,4);
cada1td1(Gator1Data.Index1) = x.dparams.alphas;
cada1td1 = cada1tf2.'*cada1td1;
cada1td1 = cada1td1(:);
mx.dparams.alphas = cada1td1(Gator1Data.Index2);
%User Line: mx = max(x);
cada1tempdparams.alphas = mx.dparams.alphas(Gator1Data.Index3);
cada1td1 = zeros(16,1);
cada1td1(Gator1Data.Index4) = x.dparams.alphas;
cada1td1 = cada1td1 + -cada1tempdparams.alphas;
cada1f1dparams.alphas = cada1td1;
cada1f1 = x.f - mx.f;
cada1tf1 = cada1f1(Gator1Data.Index5);
emx.dparams.alphas = exp(cada1tf1(:)).*cada1f1dparams.alphas;
emx.f = exp(cada1f1);
%User Line: emx = exp(x-mx);
cada1td1 = zeros(4,4);
cada1td1(Gator1Data.Index6) = emx.dparams.alphas;
cada1td1 = sum(cada1td1,1);
semx.dparams.alphas = cada1td1(:);
semx.f = sum(emx.f);
%User Line: semx = sum(emx);
cada1f1dparams.alphas = 1./semx.f.*semx.dparams.alphas;
cada1f1 = log(semx.f);
cada1td1 = cada1f1dparams.alphas;
cada1td1 = cada1td1 + mx.dparams.alphas;
out.dparams.alphas = cada1td1;
out.f = cada1f1 + mx.f;
%User Line: out = log(semx) + mx;
end


function ADiGator_LoadData()
global ADiGator_gmm_objective_adigator_d
ADiGator_gmm_objective_adigator_d = load('gmm_objective_adigator_d.mat');
return
end