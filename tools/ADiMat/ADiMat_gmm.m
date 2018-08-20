function [tf, tJ] = ...
    ADiMat_gmm(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit, replicate_point,do_adimat_vector)
%adimat_run_gmm_tests
%   compute derivative of gmm

if nargin < 8
    do_adimat_vector = false;
end
if nargin < 7
    replicate_point = false;
end

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

do_F_mode = false;

addpath('../../submodules/adimat-0.6.2-5288');
ADiMat_startup
addpath('../../submodules/awful/matlab');
addpath('../matlab-common');
independents = [1 2 3];

if do_adimat_vector
    adimat_translate_if_new(@gmm_objective_vector_repmat, independents, do_F_mode);
else
    adimat_translate_if_new(@gmm_objective, independents, do_F_mode);
end

[paramsGMM,x,hparams] = load_gmm_instance([dir_in fn '.txt'], replicate_point);

if do_adimat_vector
    objective = @gmm_objective_vector_repmat;
else
    objective = @gmm_objective;
end

if nruns_f > 0
    tic
    for i=1:nruns_f
        fval = objective(paramsGMM.alphas,paramsGMM.means,...
            paramsGMM.inv_cov_factors,x,hparams);
    end
    tf = toc/nruns_f;
else
    tf = 0
end

if nruns_J > 0
    tic
    for i=1:nruns_J
        [J, fval_] = adimat_run_gmm(do_F_mode,do_adimat_vector,...
            paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
            x,hparams);
    end
    tJ = toc/nruns_J;
else
    tJ = 0
end

fid=fopen([dir_out fn '_times_ADiMat.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end