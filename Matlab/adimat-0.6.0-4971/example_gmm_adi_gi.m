function g = example_gmm_adi_Jac(alphas, mus, Ls, x)
K = length(alphas);
lse = zeros(K,1, 'like', alphas);
for k=1:K
  L0 = Ls(:,:,k);
  L = tril(L0, -1) + diag(exp(diag(L0)));
  
  mahal = L*(mus(:,k) - x);
  lse(k) = alphas(k) + sum(diag(L0)) - 0.5*(mahal'*mahal);
end
g = sum(exp(lse))/(sum(exp(alphas)));

end