function [params, x, hparams] = load_gmm_instance( fn, replicate_point )
%LOAD_GMM_INSTANCE 
%       format:
%           d k n
%           alpha1
%           alpha2
%           .
%           alphak
%           mean1 (in row)
%           .
%           meank (in row)
%           inv_cov_factors1 (in row)
%           .
%           inv_cov_factorsk (in row)
%           x1 (in row)
%           .
%           xn (in row)
%           hparams1 hparams2

if ~exist('replicate_point','var')
    replicate_point = false;
end

fid = fopen(fn,'r');

d = fscanf(fid,'%i',1);
k = fscanf(fid,'%i',1);
n = fscanf(fid,'%i',1);
icf_sz = d*(d + 1) / 2;

params = [];
params.alphas = fscanf(fid,'%lf',[1 k]);
params.means = fscanf(fid,'%lf',[d k]);
params.inv_cov_factors = fscanf(fid,'%lf',[icf_sz k]);
if replicate_point
    x_ = fscanf(fid,'%lf',[d 1]);
    x = repmat(x_,1,n);
else
    x = fscanf(fid,'%lf',[d n]);
end

hparams = [0 0]; 
hparams(1) = fscanf(fid,'%lf',1);
hparams(2) = fscanf(fid,'%i',1);

fclose(fid);

end

