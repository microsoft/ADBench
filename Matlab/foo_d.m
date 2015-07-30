function dy = foo_d(r,X)

theta = sqrt(sum(r.^2));
dtheta = r'/theta;
dtheta_inverse = -dtheta/theta^2;
w = r/theta;
dw = eye(3)/theta + r*dtheta_inverse;
tmp = (1-cos(theta))*(w'*X);
dtmp = X'*dw*(1-cos(theta)) + (w'*X)*(sin(theta)*dtheta);
w_cross_X = [w(2)*X(3) - w(3)*X(2);
             w(3)*X(1) - w(1)*X(3);
             w(1)*X(2) - w(2)*X(1)];
dw_cross_X = [0,     X(3),  -X(2);
              -X(3), 0,     X(1);
              X(2),  -X(1), 0] * dw;
dy = -X*sin(theta)*dtheta + sin(theta)*dw_cross_X + ...
    w_cross_X*cos(theta)*dtheta + tmp*dw + w*dtmp;
end

function dy = rodrig_d(r,X)

theta = sqrt(sum(r.^2));
dtheta = r'/theta;
dtheta_inverse = -dtheta/theta^2;
w = r/theta;
dw = eye(3)/theta + r*dtheta_inverse;
tmp = (1-cos(theta))*(w'*X);
dtmp = X'*dw*(1-cos(theta)) + (w'*X)*(sin(theta)*dtheta);
w_cross_X = [w(2)*X(3) - w(3)*X(2);
             w(3)*X(1) - w(1)*X(3);
             w(1)*X(2) - w(2)*X(1)];
dw_cross_X = [0,     X(3),  -X(2);
              -X(3), 0,     X(1);
              X(2),  -X(1), 0] * dw;
dy = -X*sin(theta)*dtheta + sin(theta)*dw_cross_X + ...
    w_cross_X*cos(theta)*dtheta + tmp*dw + w*dtmp;

end