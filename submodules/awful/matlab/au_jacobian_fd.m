function J = au_jacobian_fd(f,x,JacobPattern,delta)
% AU_JACOBIAN_FD Finite-difference jacobian
%     J = AU_JACOBIAN_FD(f,x, opts)
%     With opts an au_opts structure defaulting to
%         delta = 1e-4      -- Added to each element of x
%         verbose = 1       -- Be verbose
%

% awf, jun13

if nargin == 0
  %% Test case

  au_test_begin
  f = @(x) [norm(x); norm(x).^3];
  jac = @(x1,x2) ...
    [   x1/(x1^2 + x2^2)^(1/2),   x2/(x1^2 + x2^2)^(1/2)
    3*x1*(x1^2 + x2^2)^(1/2), 3*x2*(x1^2 + x2^2)^(1/2)];
  x = rand(2,1);
  fdJ = au_jacobian_fd(f, x);
  gtJ = jac(x(1),x(2));
  
  au_test_equal gtJ fdJ 1e-4
  
  % Test with JacobPattern
  x = rand(2,1);
  f = @(x) [x(1) - 1, 2*x(2) - 2];
  Jdense = au_jacobian_fd(f, x);
  
  J = au_jacobian_fd(f, x, Jdense ~= 0);
  
  au_test_equal J Jdense 1e-4
  
  clear J
  au_test_end
  return
end

if nargin < 3
  JacobPattern = [];
end

if nargin < 4
  delta = 1e-5;
end

% Typically has to be forward diffs because sfdnls does so.
FWD = 1;

if isempty(JacobPattern)
  % Full
  fx = f(x);
  n = length(fx);
  p = length(x);
  J = sparse(n,p);
  au_assert_equal p numel(x)
  for k=1:p
    e = zeros(size(x));
    e(k) = delta;
    if FWD
      xp = x+e;
      scale = 1/(xp(k)-x(k));  % sfdnls just uses delta here, so there will be differences
      J(:,k) = (f(xp) - fx)*scale;
    else
      xp = x+e;
      xm = x-e;
      scale = 1/(xp(k)-xm(k));
      J(:,k) = (f(xp) - f(xm))*scale;
    end
    au_progressbar_ascii('au_jacobian_fd', k/p);
  end
else
  % With JacobPattern
  n = size(JacobPattern, 2);
  p = colamd(JacobPattern)';
  p = (n+1)*ones(n,1)-p;
  group = color(JacobPattern,p);

  if max(group) == n
    % No point in sfdnls, and the call to finitedifferences in there hides
    % exceptions thrown in f
    J = au_jacobian_fd(f, x, [], delta);
  else
    finDiffOpts.DiffMinChange = delta;
    finDiffOpts.DiffMaxChange = delta;
    
    fx = f(x);
    J = sfdnls(x,fx(:),JacobPattern,group,[],f,-inf+x, inf+x, ...
      finDiffOpts,[],[]);
  end
end
