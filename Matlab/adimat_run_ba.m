function [J, fval] = adimat_run_ba(do_F_mode,...
    cams,X,w,obs)
%adimat_run_ba Call already translated function 
%                   and create our gradient

if do_F_mode
   error('adimat_run_ba: forward not implemented.'); 
end

%other options include:
%   arrderivclass, arrderivclassvxdd, opt_derivclass,
%   opt_sp_derivclass, mat_derivclass, or scalar_directderivs
adimat_derivclass('arrderivclass');

p = size(obs,2);
reproj_err_d = zeros(2*p,11 + 3 + 1);
reproj_err = zeros(2,p);
for i=1:p
    idx = (2*(i-1))+1;
    [reproj_err(:,i), reproj_err_d([idx idx+1],:)] = ...
        compute_reproj_err_d(...
        cams(:,obs(1,i)),X(:,obs(2,i)),w(i),obs(3:4,i));
end

adimat_derivclass('scalar_directderivs');
w_err_d = zeros(1,p);
w_err = zeros(1,p);
for i=1:p
    [w_err(i), w_err_d(i)] = compute_w_err_d(w(i));
end

fval = [reproj_err(:); w_err(:)];
J = [reproj_err_d(:); w_err_d(:)];

end

function [fval, J] = compute_reproj_err_d(cam, X, w, feat)

clear('-global', 'init_a_*');
clear adimat_stack_info;

a_err = createFullGradients([1;1]);
[a_cam, a_X, a_w, fval] = a_ba_compute_reproj_err(cam, X, w, feat, a_err);
J = admJacRev(a_cam, a_X, a_w);

end

function [fval, J] = compute_w_err_d(w)

clear('-global', 'init_a_*');
clear adimat_stack_info;

a_w_err = 1;
[J, fval] = a_compute_w_err(w, a_w_err);

end
