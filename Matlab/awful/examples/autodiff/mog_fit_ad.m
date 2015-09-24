function out = mog_fit_ad(x,GX,mog_init)

% mog_fit_ad  Fit mixture of gaussians using fminunc
%             out = mog_fit_ad(x)

if nargin == 0
  mog_fit_ad_demo
end

if nargin < 1
  GX = 0;
end

if GX
  if size(x,1) < 200
    MARKERSIZE = 1;
  else
    MARKERSIZE = .1;
  end
end


d = size(x,2);
au_assert_equal('d', 'ad_logmog_dim');
K = ad_logmog_K;

% Set mixing params
params = 1/K * ones(K,1);

% Set Gaussian params
idx = find(tril(ones(d,d)));
for k=1:K
  if nargin > 2
    L = chol(inv(mog_init(k).covariance))';
    mu = mog_init(k).mean(:);
  else
    L = eye(d)*10; % chol(inv(mog_init(k).covariance))';
    mu = rand(d,1); % ;mog(k).mean(:);
  end
  l = L(idx); %#ok<*FNDSB>
  params = [params; l; mu]; %#ok<*AGROW>
end
init_params = params;

f % Reset emin

fun = @(t) f(t,x,GX);

fun(init_params);

for algi = {'ls' }
  alg = algi{1};
  opts = optimset('fminunc');
  opts.Display = 'off';
  opts.TolFun = 1e-7;
  switch alg
    case 'ls'
      opts.GradObj = 'on';
      opts.Hessian = 'on';
      opts.LargeScale = 'on';
    case 'ms'
      opts.GradObj = 'on';
      opts.Hessian = 'off';
      opts.LargeScale = 'off';
    case 'msnog'
      opts.GradObj = 'off';
      opts.Hessian = 'off';
      opts.LargeScale = 'off';
    otherwise
      error('bad alg')
  end
  
  tic
  [params,E,EXITFLAG,fout] = fminunc(fun, init_params, opts);
  t = toc;
  fprintf('%s: iters = %d, E = %g, %g sec\n', alg, fout.iterations, E, t);
  % fprintf('msg:%s\n', fout.message);
  out.(alg).mog = mog_from_params(params,d,K);
  %EE = -sum(log(mog_pdf(out.mog, x) * (2*pi))) / size(x,1);
  %assert_equal(E,EE,1e-7); not equal now, as wishart is in ad_logmog
  % fprintf('newton iters = %d, E = %g, %g sec, %s\n', fout.iterations, E, t, fout.message);
  out.(alg).E = E;
  out.(alg).time = t;
  out.(alg).iters = fout.iterations;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [e,J,H] = f(theta, data, GX)
    persistent emin
    if nargin < 1
      % called with no arguments means initialization
      emin = Inf;
      return
    end
    
    K = ad_logmog_K;
    [n,d] = size(data);
    npg = d + d*(d+1)/2; % Number of parameters for each Gaussian
    np = K*npg + K; % Total number of parameters (including weights)
    au_assert_equal('np','size(theta(:),1)');
    params = repmat(theta(:),[1 n]);
    
    if 1
      % Now add a column to data in order to condition the
      % log of sum of exponentials
      l=[];
      for k=K:-1:1
        params_k = theta(K+(k-1)*npg + [1:npg]);
        lk = ad_mahalanobis_mex(repmat(params_k,1,n),data(:,1:2)');
        l(k,:) = lk(1,:);
      end
      data(:,3) = min(l)/2';
    end
    
    % Compute data likelihoods
    l_out = ad_logmog_mex(params,data');
    S = sum(l_out,2) / n; % Divide by n to keep errors near unity for optimizers
    e = S(1); % Offset of 5 just to make printing pretty
    if ~isfinite(e)
      keyboard
    end
    J = S(1+[1:np]);
    if size(S,1) == np+1
      error('ad_logmog_mex has no hessian -- re-run vgg_autodiff_make_code');
    end
    H = reshape(S(1+np+[1:np*np]), np,np);
    
    % Compute prior
    %e_prior = 0;
    %wishart_a = 1;
    
    % Add Wishart priors
    %e_prior = e_prior + wishpdflnchol(Lk,wishart_a);
    %e = e - 0.01*e_prior;
    
    % draw
    if GX && (e < emin)
      emin = e;
      
      if GX>1
        subplot(121)
        cla
        imagesc(awf_colorize_diff_image(abs(H).^.2.*sign(H)))
        axis ij
        vline(K+0.5);
        hline(K+0.5);
        
        subplot(122)
      end
      
      hold off
      plot(data(:,1), data(:,2),'k.', 'markersize', MARKERSIZE);
      axis([-.3 1.3 -.3 1.3])
      hold on
      
      mog = mog_from_params(theta,d,K);
      set(mog_ellipses(mog), 'color', [0 .7 0]);
      axis([-.3 1.3 -.3 1.3])
      
      if 0
        nn = 100;
        [xx,yy] = meshgrid(linspace(-.4, 1.4, nn), linspace(-.5, 1.5, nn));
        data = [xx(:) yy(:) ones(size(xx(:)))];
        l = ad_logmog_mex(repmat(theta(:), [1 size(data,1)]), data');
        l = reshape(l(1,:), size(xx));
        contour(xx,yy,exp(-l))
      end
      
      drawnow
    end
    
  end
end
