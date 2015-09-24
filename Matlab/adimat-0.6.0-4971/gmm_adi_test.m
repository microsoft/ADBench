 %start   (to set enviroment variables) 
 clear all 
 start
 
 %% ------------------------------------------------------------
 %create a random instance for GMM
 K  = 10;
 d = 7;
 alphas = randn(K,1);
 mus = randn(d,K);
 Ls = randn(d,d,K);
 x = randn(d,1);
 

 %% -------------------------------------------------------------
 tfor = 0;
 tforV = 0;
 trev = 0
 count = 100;
 
 
 %just E
 tic
 for i = 1:count
     %differentiate the function only with respect to the first 3 groups of
     %variables (not x)
     example_gmm_adi(alphas, mus, Ls, x);     
 end
 tE = toc
 
  %reverse AD mode
 tic
 for i = 1:count    
    %functionRestuts - provide the size of the output 
    %opts.functionResults = {1};
    %or run the function [n11] = example_gmm_adi(alphas, mus, Ls, x)
    %(otherwise admDiffRex runs the function each time
    revJac = admDiffRev(@example_gmm_adi, 1, alphas, mus, Ls, x, admOptions('i', [1,2,3],  'functionResults', {1}));
 end
 trev = toc
 
 %%
 %forward AD mode
 tic
 for i = 1:count
     %differentiate the function only with respect to the first 3 groups of
     %variables (not x)
     [forJac, fout] = admDiffFor(@example_gmm_adi, 1, alphas, mus, Ls, x,  admOptions('i', [1,2,3]));     
 end
 tfor = toc
 
 
 %new Vector forward mode
 tic
  for i = 1:count
     %differentiate the function only with respect to the first 3 groups of
     %parameters (not x)
     [forJacV, foutV] = admDiffVFor(@example_gmm_adi, 1, alphas, mus, Ls, x,  admOptions('i', [1,2,3]));     
 end
 tforV = toc
 

 %finite diferences
 dJac = admDiffFD(@example_gmm_adi, 1, alphas, mus, Ls, x, admOptions('i', [1,2,3]));
 %complex variable - Lyness Moler
 cJac = admDiffComplex(@example_gmm_adi, 1, alphas, mus, Ls, x, admOptions('i', [1,2,3]));
 
 
 max(abs(forJac - forJacV))
 max(abs(forJac - revJac))
 max(abs(forJac - dJac))
 
 
 
 %% -----------------------------------------------------------------------
 
 %transform code if not yet transformed
 %admTransform(@example_gmm_adi)
 %admTransform(@example_gmm_adi, admOptions('m', 'f')); % produces d_example_gmm_adi.m
 %admTransform(@lighthouse, admOptions('m', 'r')); 
 
 % calling transformed function 
 % createFullGradients doesnt work
  adimat_derivclass('opt_derivclass'); % select runtime environment
 % adimat_derivclass('arrderivclass'); % possible alternative
  %seed matrix - with as many rows as variables
 S = eye(K+d*d*K+d*K);
 [g_alphas,g_mus,g_Ls] = createSeededGradientsFor(S, alphas,mus,Ls);
 %run transformed function
 [g_nll, nll]= g_example_gmm_adi(g_alphas, alphas, g_mus, mus, g_Ls, Ls, x);
 %extract jacobian
 Jacobian = admJacFor(g_nll);
 %derivation wrt ith variable g_nll{i}, forVFD dirder = reshape(d_nll(i, :), size(nll));
 
 % for vector forward mode
 %adimat_derivclass('vector_directderivs'); % select runtime environment
 
 %reverse mode
  %first run the function
   [nll] = example_gmm_adi(alphas,  mus, Ls, x);
   [a_nll] = createSeededGradientsRev(eye(1), nll);
   [a_alphas a_mus a_Ls nr_nll] = a_example_gmm_adi(alphas, mus, Ls, x, a_nll);
   JacobianR = admJacRev(a_alphas, a_mus, a_Ls);
 
 max(abs(Jacobian - forJac))
 max(abs(JacobianR - revJac))

%% ------------------------------------------
%as manuall as possible 
 %for scalar function f(a,b,c) we can simply use reverse mode to compute gradient
 %do we need to set this??
 adimat_derivclass('scalar_directderivs');
 [nll] = example_gmm_adi(alphas,  mus, Ls, x)
 [a_alphas a_mus a_Ls nr_nll] = a_example_gmm_adi(alphas, mus, Ls, x, 1);
 gradient = [a_alphas(:).' a_mus(:).' a_Ls(:).'];   
 
 
%forward mode 
g_alphas = zeros(size(alphas)); % create zero derivative inputs
g_mus = zeros(size(mus)); % create zero derivative inputs
g_Ls = zeros(size(Ls)); % create zero derivative inputs
%TODO
g_alphas(1) = 1; % set derivative direction
g_mus(1) = 1; % set derivative direction
g_Ls(1) = 1; % set derivative direction
[g_nll, nll]= g_example_gmm_adi(g_alphas, alphas, g_mus, mus, g_Ls, Ls, x);
dirder = g_nll(:); % extract derivative values

 
 