function err = mupad_ba_compute_reproj_err(params, data)

if nargin == 0
    %%
    addpath('..')
    addpath('../awful/matlab')
    
    % Make a small random GMM
    n = 1;
    m = 1;
    p = 1;
    [cam,X,w,obs] = generate_random_ba_instance(n,m,p);
    params.cam = cam;
    params.X = X;
    params.w = w;
    data = obs(3:4);
    
    % Flatten the parameters into a vector
    params_vector = au_deep_vectorize(params);
    
    % And make an "unflattening" function
    unvec_params = @(x) au_deep_unvectorize(params, x);
    
    % Test call of the function
    f = @(x,data) mupad_ba_compute_reproj_err(unvec_params(x), data);
    f(params_vector, data)
    
    mexname = sprintf('mupad_ba_compute_reproj_err_mex');
    
    if ~exist(mexname, 'file')
        fprintf('mupad_ba_compute_reproj_err: making mex file %s\n', mexname);
        au_autodiff_generate(f, params_vector, data, [mexname '.cxx']);
    end
    
    %%
    for dojac = 0:1
        fprintf('running trial: dojac = %d ...\n', dojac);
        [~] = feval(mexname, params_vector, data, dojac==1);
    end
    return
end


err = ba_compute_reproj_err(params.cam,...
    params.X, params.w, data);
