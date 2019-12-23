% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function adimat_translate_if_new(func,independents,do_forward_mode)

addpath('../../submodules/adimat-0.6.2-5288');
ADiMat_startup
addpath('../../submodules/awful/matlab');

func_name = [func2str(func) '.m'];
if do_forward_mode
    d_name = ['d_' func_name];
else
    d_name = ['a_' func_name];
end

a = dir(func_name);
func_age = datetime(a.date);
b = dir(d_name);
d_age = datetime(b.date);
if isempty(b) || d_age < func_age
    if do_forward_mode
        adopts = admOptions('m', 'f','independents',independents);
        adopts.flags = '--server=http://adimat.sc.informatik.tu-darmstadt.de/';
        admTransform(func, adopts);
    else
        adopts = admOptions('m', 'r','independents',independents);
        adopts.flags = '--server=http://adimat.sc.informatik.tu-darmstadt.de/';
        admTransform(func, adopts);
    end
end