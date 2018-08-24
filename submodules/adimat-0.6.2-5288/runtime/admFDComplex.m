function [b] = admFDComplex(func, seed, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end
  admCheckOptions(admOpts);

  phi0 = rand() .* 2 .* pi;
  admOpts.fdStep = sqrt(eps) .* exp(j.* phi0);
  
  JFD = admDiffFD(func, 1, funcArgs{:}, admOpts);
  
  nTests = 11;
  b = true;
  tol = sqrt(eps) .* 1e4;
  verbose = isfield(admOpts, 'x_verbose') && admOpts.x_verbose;
    
  for i=1:nTests
    
    admOpts.fdStep = sqrt(eps) .* exp(j.* (phi0 + (i ./ nTests .* 2 .* pi)));
    JFDalt = admDiffFD(func, 1, funcArgs{:}, admOpts);
    
    [rrel r] = relMaxNorm(JFD, JFDalt);
  
    if verbose
      fprintf(1, 'FD complex test step %d/%d, at angle %g: r = %g (abs. %g)\n', i,nTests,angle(admOpts.fdStep) ./ pi .* 180, rrel,r);
    end
    
    if rrel > tol 
      % if ismatrix(JFD)
      %   figure, mesh(abs(JFD))
      %   figure, mesh(abs(JFDalt))
      % elseif isvector(JFD)
      %   figure, plot(abs(JFD))
      %   figure, plot(abs(JFDalt))
      % else
      %   JFD
      %   JFDalt
      % end
      b = false;
      break;
    end
    
  end

end