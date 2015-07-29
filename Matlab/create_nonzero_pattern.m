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
P = sparse(2*p + ncams-2 + p,11*ncams+3*npts);

for i=1:p
    camIdx = obs(1,i);
    ptIdx = obs(2,i);
    
    idx = 2*(i-1) + 1;
    % camera parameters
    P([idx idx+1],((camIdx-1)*11)+(1:11)) = true;
    % point parameters
    col_off = ncams*11;
    P([idx idx+1],(col_off+(ptIdx-1)*3)+(1:3)) = true;
    % weight
    col_off = col_off + npts*3;
    P([idx idx+1],col_off+i) = true;
end

row_off = 2*p;
f_idx = 7;
for i=1:(ncams-2)
    for j=1:3
        P(row_off+i, (i-1+j-1)*11 + f_idx) = true;
    end
end

row_off = 2*p + ncams-2;
col_off = ncams*11 + npts*3;
P(row_off+(1:p),col_off+(1:p)) = logical(eye(p));

end

