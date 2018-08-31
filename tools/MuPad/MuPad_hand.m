function [tf,tJ] = ...
    MuPad_hand(dir_in, dir_out, fn, nruns_f, nruns_J, time_limit)
%MUPAD_Hand Run a single MuPad Hand test
%   (description)

addpath('../matlab-common');
addpath('../../submodules/awful/matlab');

[params, data] = load_hand_instance([dir_in fn '.txt']);

nruns_f = str2double(nruns_f);
nruns_J = str2double(nruns_J);

disp(['nruns_f: ' nruns_f ', nruns_J: ' nruns_J]);

time_limit = str2double(time_limit);

if nruns_f > 0
    tic
    for i=1:nruns_f
        err = mupad_hand_objective(params, data);
    end
    tf = toc/nruns_f;
    au_assert ~isempty(J)
else
    tf = 0
end

if nruns_J > 0
    tic
    for i=1:nruns_J
        [ J, err ] = mupad_hand_objective(params, data);
    end
    tJ = toc/nruns_J;
    au_assert ~isempty(J)
else
    tJ = 0
end

fid=fopen([dir_out fn '_times_MuPad.txt'], 'w');
fprintf(fid, '%f %f\n', [tf tJ]);
fprintf(fid, 'tf tJ\n');
fclose(fid);

end

