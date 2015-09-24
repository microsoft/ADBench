
%% Test GMM example


if nargin == 0
    %% test
    K  = 3;
    d = 7;
    alphas = randn(K,1);
    mus = randn(d,K);
    Ls = randn(d,d,K);
    x = randn(d,1);
    
    weights = exp(alphas)/sum(exp(alphas));
    likes = zeros(K,1);
    likes1 = zeros(K,1);
    for k=1:K
        L0 = Ls(:,:,k);
        L = tril(L0, -1) + diag(exp(diag(L0)));
        iCov = L'*L;
        dx = x - mus(:,k);
        likes1(k) = weights(k)*det(iCov)^0.5*exp(-0.5*dx'*iCov*dx);

        logw = alphas(k)-au_logsumexp(alphas);
        mahal = L*dx;
        likes(k) = logw + log(prod(exp(diag(L0)))) - 0.5*(mahal'*mahal);
        likes(k) = logw + sum(diag(L0)) - 0.5*(mahal'*mahal);
    end
    au_test_equal log(likes1) likes 1e-7
    nll0 = au_logsumexp(log(likes1));
    
    nll1 = example_gmm(alphas, mus, Ls, x);

    au_test_equal nll0 nll1 1e-7
    return
end

K = length(alphas);
lse = zeros(K,1, 'like', alphas);
for k=1:K
  L0 = Ls(:,:,k);
  L = tril(L0, -1) + diag(exp(diag(L0)));
  
  mahal = L*(mus(:,k) - x);
  lse(k) = alphas(k) + sum(diag(L0)) - 0.5*(mahal'*mahal);
end
nll = au_logsumexp(lse) - au_logsumexp(alphas);
