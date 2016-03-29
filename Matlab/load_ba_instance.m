function [cams, X, w, obs] = load_ba_instance( fn )
%LOAD_BA_INSTANCE format:
%           n m p
%           cam1 (row)
%           .
%           camn (row)
%           X1 (row)
%           .
%           Xm (row)
%           w1 w2 ... wp
%           obs1 (row [camIdx ptIdx])
%           .
%           obsp
%           feat1 (row [x y])
%           .
%           featp

fid = fopen(fn,'r');

n = fscanf(fid,'%i',1);
m = fscanf(fid,'%i',1);
p = fscanf(fid,'%i',1);

cams = fscanf(fid,'%lf',[11 1]);
cams = repmat(cams,1,n);
X = fscanf(fid,'%lf',[3 1]);
X = repmat(X,1,m);
w = fscanf(fid,'%lf',[1 1])';
w = repmat(w,1,p);
feat = fscanf(fid,'%lf',[2 1]);

obs = zeros(4,p);
camIdx = 1;
ptIdx = 1;
for i=1:p
    obs(1,i) = camIdx;
    obs(2,i) = ptIdx;
    camIdx = mod(camIdx,n)+1;
    ptIdx = mod(ptIdx,m)+1;
end
obs(3:4,:) = repmat(feat,1,p);

% cams = fscanf(fid,'%lf',[11 n]);
% X = fscanf(fid,'%lf',[3 m]);
% w = fscanf(fid,'%lf',[p 1])';
% obs = fscanf(fid,'%i',[2 p]) + 1; % to indexing from 1
% obs(3:4,:) = fscanf(fid,'%lf',[2 p]);

fclose(fid);

end

