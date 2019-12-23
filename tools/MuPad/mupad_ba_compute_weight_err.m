% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function err = mupad_ba_compute_weight_err(w, data)

if nargin == 0
    %%
    addpath('..')
    addpath('../awful/matlab')
    
    % Make a small random GMM
    w = rand(1);
    data = zeros(0,1);
    
    % Test call of the function
    f = @mupad_ba_compute_weight_err;
    f(w, data)
    
    mexname = sprintf('mupad_ba_compute_weight_err_mex');
    
    if ~exist(mexname, 'file')
        fprintf('mupad_ba_compute_weight_err: making mex file %s\n', mexname);
        au_autodiff_generate(f, w, data, [mexname '.cxx']);
    end
    
    %%
    for dojac = 0:1
        fprintf('running trial: dojac = %d ...', dojac);
        [~] = feval(mexname, w, data, dojac==1);
    end
    return
end


err = 1-w^2;
