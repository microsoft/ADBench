function dz = foo_d(k,x)


y = x(1:2)/x(3);
rsq = sum(y.^2);
z = y*(1 + k(1)*rsq + k(2)*rsq*rsq);

ddistort = eye(2)*(1 + k(1)*rsq + k(2)*rsq*rsq) + y*(k(1)*2 + k(2)*4*rsq)*y';

% dnorm = [1/x(3) 0 -x(1)/x(3)^2;
%         0   1/x(3) -x(2)/x(3)^2];
dnorm = [-x(1)/x(3)^2;
        -x(2)/x(3)^2];

dz = ddistort(:,1:2)/x(3);
dz(:,3) = ddistort*dnorm;

end

% function dy = rodri_d(r,X)
% 
% theta = sqrt(sum(r.^2));
% dtheta = r'/theta;
% dtheta_inverse = -dtheta/theta^2;
% w = r/theta;
% dw = eye(3)/theta + r*dtheta_inverse;
% tmp = (1-cos(theta))*(w'*X);
% dtmp = X'*dw*(1-cos(theta)) + (w'*X)*(sin(theta)*dtheta);
% w_cross_X = [w(2)*X(3) - w(3)*X(2);
%              w(3)*X(1) - w(1)*X(3);
%              w(1)*X(2) - w(2)*X(1)];
% dw_cross_X = [0,     X(3),  -X(2);
%               -X(3), 0,     X(1);
%               X(2),  -X(1), 0] * dw;
% dy = -X*sin(theta)*dtheta + sin(theta)*dw_cross_X + ...
%     w_cross_X*cos(theta)*dtheta + tmp*dw + w*dtmp;
% end