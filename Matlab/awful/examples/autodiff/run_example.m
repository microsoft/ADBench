
% Fit a Gaussian mixture model to some points...

%% First, get some points
n1 = 200;
n2 = 200;
points = [
  randn(n1,2)*[4 1; -1 2] + au_bsx([.3 .3])
  randn(n2,2)*[2 1; -.4 .3] + au_bsx([0 -4])
  ];
plot(points(:,1), points(:,2), '.')


%% Define initial estimate

K = 3;
d = 2;
alphas = rand(1,K);
mus = randn(d,K);
Ls = randn(d,d,K);

%%

