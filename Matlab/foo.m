function z = foo(k,x)

y = x(1:2)/x(3);
rsq = sum(y.^2);
z = y*(1 + k(1)*rsq + k(2)*rsq*rsq);

end

% function y = rodri(r,X)
% 
% 
% theta = sqrt(sum(r.^2));
% w = r/theta;
% tmp = (1-cos(theta))*(w'*X);
% w_cross_X = [w(2)*X(3) - w(3)*X(2);
%              w(3)*X(1) - w(1)*X(3);
%              w(1)*X(2) - w(2)*X(1)];
% y = cos(theta)*X + w_cross_X*sin(theta)+tmp*w;
% 
% end