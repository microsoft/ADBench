function R = au_rodrigues(axis, angle)

% AU_RODRIGUES  Convert axis/angle representation to rotation
%               R = AU_RODRIGUES(AXIS*ANGLE)
%               R = AU_RODRIGUES(AXIS, ANGLE)
%               This is deigned to be fast primarily if used with au_autodiff

% awf, apr07
% a lot of code removed (filip srajer jul15)


if nargin >= 2
    w = axis*angle;
else
    w = axis;
end

theta = sqrt(sum(w.^2));
n = w / theta;
n_x = au_cross_matrix(n);
R = eye(3) + n_x*sin(theta) + n_x*n_x*(1-cos(theta));
        
% w1 = w(1);
% w2 = w(2);
% w3 = w(3);
% 
% t2 = w2*w2;
% t3 = w1*w1;
% t4 = w3*w3;
% t5 = t2+t3+t4 + eps;
% 
% %%
% t7 = sqrt(t5);
% t8 = cos(t7);
% t10 = sin(t7);
% t9 = t8-1.0;
% t11 = 1.0/t7;  %% ->1/t7
% t13 = t10*t11*w2;
% 
% t6 = 1.0/t5;
% t12 = t4*t6;
% t14 = t3*t6;
% t15 = t2*t6;
% t17 = t12+t15;
% t23 = t12+t14;
% t32 = t14+t15;
% 
% R = [
%  t9*t17+1.0, ...
%  -t10*t11*w3-t6*t9*w1*w2, ...
%  t13-t6*t9*w1*w3;
% 
%  t10*t11*w3-t6*t9*w1*w2, ...
%  t9*t23+1.0, ...
%  -t10*t11*w1-t6*t9*w2*w3;
% 
%  -t13-t6*t9*w1*w3, ...
%  t10*t11*w1-t6*t9*w2*w3, ...
%  t9*t32+1.0
%  ];
