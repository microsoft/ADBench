function varargout = admHessFor(handle, seed, varargin)
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  admOpts.hessianStrategy = 't2for';
  admOpts.admDiffFunction = @admTaylorFor;
  
  [varargout{1:nargout}] = admHessian(handle, seed, funcArgs{:}, admOpts);
  
end
