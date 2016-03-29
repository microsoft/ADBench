function [R, dRdw] = au_rodrigues(axis, angle, slow)

% AU_RODRIGUES  Convert axis/angle representation to rotation
%               R = AU_RODRIGUES(AXIS*ANGLE)
%               R = AU_RODRIGUES(AXIS, ANGLE)
%               This is deigned to be fast primarily if used with au_autodiff

% awf, apr07
if nargin == 0
    % unit test
    disp('**')
    disp('Testing au_rodrigues')
    axis = [1 .2 -.3]';
    axis = axis /norm(axis);
    angle = 23 / 180 * pi;
    R = au_rodrigues(axis*angle);
    Rmex = au_rodrigues_mex(axis*angle);
    Rslow = au_rodrigues(axis*angle, 1, 1);
    au_test_equal R Rslow 1e-9
    au_test_equal R Rmex 1e-9
    au_test_equal('det(R)','1',1e-15,1);
    au_test_equal('R*axis','axis',1e-15,1);
    au_test_equal au_rodrigues([0,0,0]) eye(3)
    au_test_equal au_rodrigues_mex([0,0,0]) eye(3)
    
    disp('Test timing');
    tic
    N = 10000;
    for k=1:N
        R = eye(3);
    end
    t_baseline = toc;
    %fprintf('Baseline: %.1f usec\n', t_baseline/N*1e6);
    
    tic
    for k=1:N
        R = au_rodrigues(axis, angle, 1);
    end
    t1 = toc-t_baseline;
    fprintf('Slow: %.1f usec\n', t1/N*1e6);
    
    tic
    for k=1:N
        R = au_rodrigues(axis, angle);
    end
    t2 = toc-t_baseline;
    fprintf('Fast: %.1f usec\n', t2/N*1e6);
    
    tic
    for k=1:N
        R = au_rodrigues_mex(axis*angle);
    end
    t2 = toc-t_baseline;
    fprintf('Mex: %.1f usec\n', t2/N*1e6);
    
    if t2 > t1
        disp('FAILED: Fast is slower than slow....\n');
    end
    
    %% Check derivatives
    w_to_test = [
        0 0 0
        0 0 1
        1 0 0
        0 1 0
        1 .2 -.3
        -1e-9 1e-10 -5e-10];
    for i = 1:size(w_to_test,1);
        w = w_to_test(i,:);
        fprintf('Test derivative [%g %g %g]\n', w);
        [R, dRdw] = au_rodrigues(w);
        for k=1:3
            delta = 1e-8;
            wp = w; wp(k) = wp(k) + delta;
            [Rp, ~] = au_rodrigues(wp);
            diff_fd = (Rp - R)/delta;
            au_test_equal dRdw(:,:,k) diff_fd 1e-7
        end
    end
    
    %%
    clear R
    return
end

if nargin >= 2
    w = axis*angle;
else
    w = axis;
end

if nargout == 1
    if nargin >= 3 && slow
        % Easy to understand, and useful for deriving fast one below as follows:
        if 0
            %%
            syms w1 w2 w3 real
            Rot = au_rodrigues([w1 w2 w3]);
            au_ccode([Rot; diff(Rot,w1); diff(Rot,w2); diff(Rot,w3)])
        end
        theta = sqrt(sum(w.^2));
        n = w / theta;
        n_x = au_cross_matrix(n);
        R = eye(3) + n_x*sin(theta) + n_x*n_x*(1-cos(theta));
        return
    end
end

w1 = w(1);
w2 = w(2);
w3 = w(3);

t2 = w2*w2;
t3 = w1*w1;
t4 = w3*w3;
t5 = t2+t3+t4 + eps;
% Lose this for autodiff -- adding eps makes it straight-line code...
% if t5 == 0
%     R = eye(3);
%     dRdw = zeros(3,3,3);
%     % double(subs(diff(R, w0), {w0,w1,w2}, {0,0,1e-5}))
%     dRdw(:,:,1) = [ 0  0 0; 0 0 -1;  0 1 0 ];
%     dRdw(:,:,2) = [ 0  0 1; 0 0  0; -1 0 0 ];
%     dRdw(:,:,3) = [ 0 -1 0; 1 0  0;  0 0 0 ];
%     return
%end

%%
t7 = sqrt(t5);
t8 = cos(t7);
t10 = sin(t7);
t9 = t8-1.0;
t11 = 1.0/t7;  %% ->1/t7
t13 = t10*t11*w2;

t6 = 1.0/t5;
t12 = t4*t6;
t14 = t3*t6;
t15 = t2*t6;
t17 = t12+t15;
t23 = t12+t14;
t32 = t14+t15;

R = [
 t9*t17+1.0, ...
 -t10*t11*w3-t6*t9*w1*w2, ...
 t13-t6*t9*w1*w3;

 t10*t11*w3-t6*t9*w1*w2, ...
 t9*t23+1.0, ...
 -t10*t11*w1-t6*t9*w2*w3;

 -t13-t6*t9*w1*w3, ...
 t10*t11*w1-t6*t9*w2*w3, ...
 t9*t32+1.0
 ];

if nargout <= 1
    return
end


%%
t16 = 1.0/(t5*t5);
t18 = t7^(-3);
t19 = t10*t18*w1*w3;
t20 = t3*t10*t18*w2;
t21 = t3*t9*t16*w2*2.0;
t22 = t4*t16*w1*2.0;
t24 = t6*t8*w1*w2;
t25 = t3*t10*t18*w3;
t26 = t3*t9*t16*w3*2.0;
t27 = t3*t10*t18;
t28 = t9*t16*w1*w2*w3*2.0;
t29 = t10*t18*w1*w2*w3;
t30 = t3*t16*w1*2.0;
t31 = t2*t16*w1*2.0;
t33 = t10*t11;
t34 = t10*t18*w2*w3;
t35 = t2*t10*t18*w1;
t36 = t2*t9*t16*w1*2.0;
t37 = t4*t16*w2*2.0;
t38 = t10*t18*w1*w2;
t39 = t2*t6*t8;
t40 = t2*t10*t18*w3;
t41 = t2*t9*t16*w3*2.0;
t42 = t2*t16*w2*2.0;
t43 = t3*t16*w2*2.0;
t44 = t6*t8*w2*w3;
t45 = t4*t10*t18;
t46 = t4*t16*w3*2.0;
t47 = t6*t8*w1*w3;
t48 = t4*t10*t18*w1;
t49 = t4*t9*t16*w1*2.0;
t50 = t4*t10*t18*w2;
t51 = t4*t9*t16*w2*2.0;
t52 = t3*t16*w3*2.0;
t53 = t2*t16*w3*2.0;

dRdw = zeros(3,3,3);
dRdw(:,:,1) = [
-t9*(t22+t31)-t10*t11*t17*w1, ...
t19+t20+t21-t6*t9*w2-t6*t8*w1*w3, ...
t24+t25+t26-t6*t9*w3-t10*t18*w1*w2;
-t19+t20+t21+t47-t6*t9*w2, ...
-t9*(t22+t30-t6*w1*2.0)-t10*t11*t23*w1, ...
t27+t28+t29-t10*t11-t3*t6*t8;
-t24+t25+t26+t38-t6*t9*w3, ...
-t27+t28+t29+t33+t3*t6*t8, ...
-t9*(t30+t31-t6*w1*2.0)-t10*t11*t32*w1;
];

dRdw(:,:,2) = [
-t9*(t37+t42-t6*w2*2.0)-t10*t11*t17*w2, ...
t34+t35+t36-t6*t9*w1-t6*t8*w2*w3, ...
t28+t29+t33+t39-t2*t10*t18;
-t34+t35+t36+t44-t6*t9*w1, ...
-t9*(t37+t43)-t10*t11*t23*w2, ...
-t24+t38+t40+t41-t6*t9*w3;
t28+t29-t33-t39+t2*t10*t18, ...
t24-t38+t40+t41-t6*t9*w3, ...
-t9*(t42+t43-t6*w2*2.0)-t10*t11*t32*w2;
];

dRdw(:,:,3) = [
-t9*(t46+t53-t6*w3*2.0)-t10*t11*t17*w3, ...
t28+t29-t33+t45-t4*t6*t8, ...
-t34+t44+t48+t49-t6*t9*w1;
t28+t29+t33-t45+t4*t6*t8, ...
-t9*(t46+t52-t6*w3*2.0)-t10*t11*t23*w3, ...
t19-t47+t50+t51-t6*t9*w2;
t34-t44+t48+t49-t6*t9*w1, ...
-t19+t47+t50+t51-t6*t9*w2, ...
-t9*(t52+t53)-t10*t11*t32*w3;
];
