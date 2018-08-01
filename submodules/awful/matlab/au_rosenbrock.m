function [e, J, H] = au_rosenbrock(x,A)
% AU_ROSENBROCK Rosenbrock

if nargin == 0
  range = linspace(-1,1,100)*2;
  [xx,yy] = meshgrid(range, range+1);
  zz = xx;
  K = 10;
  for i=1:numel(xx)
    [e,J] = au_rosenbrock([xx(i), yy(i)], 10);
    zz(i) = sum(e.^2);
  end
  surfl(xx,yy,(zz/max(zz(:))).^.2); axis equal

  return
  
end

y = x(2);
x = x(1);

e = [
  A*(y-x.^2)
  (1-x)
  ];

if nargout > 1
  J = [
    -2*A*x A
    -1    0
    ];
end

if nargout > 2
  Hx = [
    -20 0
      0 0
      ];
  Hy = [
    0 0 
    0 0 
    ];
  H = cat(3, Hx,Hy);
end
