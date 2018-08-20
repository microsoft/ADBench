function [aopts sys] = adimat_built_linsolve_adjopts(opts, sys)
  aopts = struct();
  sysset = false;
  if isfield(opts, 'POSDEF')
    aopts.POSDEF = opts.POSDEF;
  end
  if isfield(opts, 'SYM')
    aopts.SYM = opts.SYM;
  end
  if isfield(opts, 'RECT')
    aopts.RECT = opts.RECT;
  end
  if isfield(opts, 'LT')
    aopts.LT = opts.LT;
  end
  if isfield(opts, 'UT')
    aopts.UT = opts.UT;
  end
  if isfield(opts, 'TRANSA')
    aopts.TRANSA = ~opts.TRANSA;
  else
    aopts.TRANSA = true;
  end
  if isfield(opts, 'UHESS')
    if opts.UHESS
      aopts.UHESS = opts.UHESS;
    end
  end
end
% $Id: adimat_build_linsolve_adjopts.m 4170 2014-05-13 08:31:25Z willkomm $
