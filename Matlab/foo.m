function y = foo(cam,X)

end

function y = rodrig(r,X)

theta = sqrt(sum(r.^2));
w = r/theta;
tmp = (1-cos(theta))*(w'*X);
w_cross_X = [w(2)*X(3) - w(3)*X(2);
             w(3)*X(1) - w(1)*X(3);
             w(1)*X(2) - w(2)*X(1)];
y = cos(theta)*X + w_cross_X*sin(theta)+tmp*w;

end