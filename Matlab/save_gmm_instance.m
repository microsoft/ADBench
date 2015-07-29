function save_gmm_instance( fn, params, x, hparams)
%SAVE_GMM_INSTANCE 
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

alphas = params.alphas;
means = params.means;
icf = params.inv_cov_factors;
d = size(x,1);
k = size(alphas,2);
n = size(x,2);

fid = fopen(fn,'w');

fprintf(fid,'%i %i %i\r\n',d,k,n);

for i=1:k
    fprintf(fid,'%f\r\n',alphas(i));
end

for i=1:k
    for j=1:d
        fprintf(fid,'%f ',means(j,i));
    end
    fprintf(fid,'\r\n');
end

for i=1:k
    for j=1:size(icf,1)
        fprintf(fid,'%f ',icf(j,i));
    end
    fprintf(fid,'\r\n');
end

for i=1:n
    for j=1:d
        fprintf(fid,'%f ',x(j,i));
    end
    fprintf(fid,'\r\n');
end

fprintf(fid,'%f ',hparams(1));
fprintf(fid,'%i ',hparams(2));
fprintf(fid,'\r\n');

fclose(fid);

end

