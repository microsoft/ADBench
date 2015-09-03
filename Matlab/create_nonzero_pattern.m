function P = create_nonzero_pattern( ncams, npts, obs )
%create_nonzero_pattern 
%         CAMERAS c x n 
%               matrix containing parameters of n cameras
%               for now, supported format is only
%                 [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]'
%               r1,r2,r3 are angle-axis rotation parameters (Rodrigues)
%               [C1 C2 C3]' is the camera center
%               f is the focal length in pixels
%               [u0 v0]' is the principal point
%               k1,k2 are radial distortion parameters
%         X 3 x m 
%               matrix containg m points
%         W 1 x p 
%               vector of weigths for Zach robustifier
%         OBS 2 x p 
%               contains p observations
%               i.e. [camIdx ptIdx x y]
%               where [x y]' is a measurement (a feature)   
%         P p x (11*ncams+3*npts) pattern

p = size(obs,2);
nnz = 2*p*(11+3+1) + p; %num non zero
rows = repmat(1:2*p,11+3+1,1);
rows = [rows(:); 2*p+(1:p)'];
cols = zeros(1,nnz);
vals = true(1,nnz);

camCols = (obs(1,:)-1)*11;
ptCols = (obs(2,:)-1)*3 + 11*ncams;
wCols = (0:p-1) + 3*npts + 11*ncams;

idx = 1;
for i=1:p
    
    for j=1:2
        cols(idx:idx+10) = (1:11) + camCols(i);
        idx = idx+11;
        
        cols(idx:idx+2) = (1:3) + ptCols(i);
        idx = idx+3;
        
        cols(idx) = 1 + wCols(i);
        idx = idx+1;
    end
end

cols(end-p+1:end) = 11*ncams+3*npts+(1:p);
P = sparse(rows,cols,vals);

end

