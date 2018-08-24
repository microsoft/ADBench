function [tf,tJ] = ...
    MuPad_ba(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit)
%MUPAD_GMM Run a single MuPad BA test
%   (description)

addpath('../matlab-common');
addpath('../../submodules/awful/matlab');

[cams, X, w, obs] = load_ba_instance([dir_in fn '.txt']);

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

disp(['nruns_f: ' nruns_f ', nruns_J: ' nruns_J]);

time_limit = str2double(time_limit);

if nruns_f > 0
	tic
	for i=1:nruns_f
		[~,reproj_err,w_err] = mupad_ba_objective(cams, X, w, obs, false);
	end
	tf = toc/nruns_f;
end

if nruns_J > 0
    tic
	for i=1:nruns_J
		[J, reproj_err,w_err] = mupad_ba_objective(cams, X, w, obs, true);
	end
	tJ = toc/nruns_J;
end

fid=fopen([dir_out fn '_times_MuPad.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end
