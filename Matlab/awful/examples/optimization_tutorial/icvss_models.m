%%
clear

%%
pdf = @(x,mu,sigma) ...
    det(2*pi*sigma^2)^(-1/2)*exp(-1/2*(x-mu)'*sigma^-2*(x-mu))

%%
syms x mu sigma real

p = simple(-log(pdf(x,mu,sigma))*2 - sym('log(2)+log(pi)'))

%%
c = 1.3; 
sigma = .3; 
x = randn(1000,1)*sigma + c; 

clf
hist(x,120)
[mean(x) std(x)]

%%
log_p = @(mu,sigma) sum((x-mu).^2./sigma.^2 + log(sigma.^2));

%% Plot it
[m,s] = meshgrid(-1:.1:3, 0:.03:1.5);
z = m; 
for k=1:numel(z(:)), 
    z(k) = log_p(m(k), s(k)); 
end
clf
mesh(m(1,:),s(:,1),(z - min(z(:)))*10 + 1)
set(gca, 'zsc', 'log', 'zlim', [1 1e7])
view(-50, 30)

%%
disp('*** Calling fminunc ***')
params = fminunc(@(params) log_p(params(1), params(2)), [0 1])
mean_var = [mean(x) std(x)]

%%
disp('*** Prior on sigma ***')
lambda = 1520.5;
log_map = @(mu,sigma) log_p(mu,sigma) + lambda*sigma

params = fminunc(@(params) log_map(params(1), params(2)), [0 1])
mean_var = [mean(x) std(x)]

%%
disp('*** Prior on sigma ***')
lambda = 1520.5;
log_map = @(mu,sigma) log_p(mu,sigma) + lambda*sigma
params = fmincon(@(params) log_map(params(1), params(2)), [0 1], [], [], [], [], [-inf 0], [])
mean_var = [mean(x) std(x)]
