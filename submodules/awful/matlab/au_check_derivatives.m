function emax = au_check_derivatives(f,x,J,varargin)
% AU_CHECK_DERIVATIVES Finite-difference derivative check
%     emax = au_check_derivatives(f,x,J, opts)
%     With opts an au_opts structure defaulting to
%         delta = 1e-4      -- Added to each element of x
%         tol = 1e-7        -- Want derivatives accurate to this tolerance
%         timeout = inf     -- Spend at most "timeout" seconds checking
%         verbose = 1       -- Be verbose
%         PatternOnly = 0   -- Used for checking JacobPattern
%         

% awf, jun13

if nargin == 0
    %% Test case
    f = @(x) [norm(x); norm(x).^3];
    jac = @(x1,x2) ...
        [   x1/(x1^2 + x2^2)^(1/2),   x2/(x1^2 + x2^2)^(1/2)
        3*x1*(x1^2 + x2^2)^(1/2), 3*x2*(x1^2 + x2^2)^(1/2)];
    au_check_derivatives(f, [.2 .3]', jac(.2, .3));
    fprintf('Should be silent [...');
    au_check_derivatives(f, [.2 .3]', jac(.2, .3), 1e-5, 1e-5, inf, 0);
    disp('] was it?');
    au_test_should_fail au_check_derivatives(f,[.2,.3]',jac(.2, .31))
    return
end

opts = au_opts('FWD=0;delta=1e-4;tol=1e-7;timeout=60;verbose=1;PatternOnly=0;IndToName=0;', varargin{:});

[~,p] = size(J);
if opts.verbose
    fprintf('au_check_derivatives: dim %d, time at most %.1f seconds...', p, opts.timeout);
end
au_assert_equal p numel(x)
% Check derivatives OK
t = clock;
emax = 0;
ks = randperm(p);
if opts.FWD
  fx = f(x);
end
numExtra = 0;

for ki=1:p
    k = ks(ki);
    e = zeros(size(x));
    e(k) = opts.delta;
    if opts.FWD
      xp = x+e;
      scale = 1/(xp(k)-x(k));
      fdJcol = (f(xp) - fx)*scale;
    else
      xp = x+e;
      xm = x-e;
      scale = 1/(xp(k)-xm(k));
      fdJcol = (f(xp) - f(xm))*scale;
    end
    % Used for checking JacobPattern, and here we check only that 
    % JacobPattern does not have incorrectly positioned zeroes.
    if opts.PatternOnly
        fdJcolb = fdJcol ~= 0;
        err = max(fdJcolb - J(:,k));
        numExtra = numExtra + sum(fdJcol == 0 & (J(:,k) ~= 0));
    else
        err = max(abs(fdJcol - J(:,k)))/norm(fdJcol);
    end
    if err > opts.tol
        err = full(err);
        fprintf(2, '\nau_check_derivatives: Error on parameter %d = %g (%dth checked, colnorm = %g)', ...
          k, err, ki, norm(fdJcol));
        if isa(opts.IndToName, 'function_handle')
          fprintf(2, '\n Param: '); opts.IndToName(k);
        end

        % error('awful:check_derivatives', 'au_check_derivatives: Error on parameter %d = %g (%dth checked)', k, err, ki);
        %%
        % hold off; plot(fdJcol,'o'); hold on; plot(J(:,k),'x');
    end
    emax = max(emax, err);
    if etime(clock, t) > opts.timeout
        if opts.verbose
            fprintf('[timeout after %d]', ki);
        end
        break
    end
end
if opts.verbose
    if opts.PatternOnly
        fprintf('[%d/%d extra zeros in JacobPattern]', numExtra, nnz(J));
    end
    fprintf('all OK\n');
end
%au_assert_equal('fdJ', 'J', tol)
