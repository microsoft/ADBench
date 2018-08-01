function au_whist_test()

% AU_WHIST_TEST Unit test for au_whist

% Andrew Fitzgibbon <awf@microsoft.com>

IMAX = 12;
tmp = randi(IMAX, 1,30000);

au_test_equal full(sparse(1,tmp,tmp)) au_whist(tmp,tmp,max(tmp))

tic; 
N = 1000;
for k=1:N
  full(sparse(1,tmp,tmp)); 
end
tsparse = toc/N;
fprintf('sparse = %.3f ms\n', tsparse*1000);

tic; 
N = 10000; 
for k=1:N
  [~] = au_whist(tmp, tmp, max(tmp)); 
end
twhist = toc/N;
fprintf('whist = %.3f ms, speedup = %g\n', twhist*1000, tsparse/twhist);
