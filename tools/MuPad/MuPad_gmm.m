function [tf,tJ] = ...
    MuPad_gmm(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit, replicate_point)
%MUPAD_GMM Run a single MuPad GMM test
%   (description)

if nargin < 7
    replicate_point = false
end

addpath('../matlab-common');
addpath('../../submodules/awful/matlab');

[paramsGMM,x,hparams] = load_gmm_instance([dir_in fn '.txt'], replicate_point);

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

disp(['nruns_f: ' nruns_f ', nruns_J: ' nruns_J]);

time_limit = str2double(time_limit);

if nruns_f > 0
    tic
    [ J, err ] = mupad_gmm_objective(nruns_f, paramsGMM, x, hparams, false);
    au_assert ~isempty(J)
end

if nruns_J > 0
    tic
    [ J, err ] = mupad_gmm_objective(nruns_J, paramsGMM, x, hparams, true);
	au_assert ~isempty(J)
end

fid=fopen([dir_out fn '_times_MuPad.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end

