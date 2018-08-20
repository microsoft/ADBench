% function [success, message] = admTransform(func, indeps, deps, flags, opts)
%
% function [success, message] = admTransform(func, opts)
%   => admTransform(func, opts.indeps, opts.deps, [opts.mode ' ' opts.flags], opts)
%
% Differentiate the function func using ADiMat in reverse mode.
%
% Use automatic differentiation to get the derivatives of func
% with respect to deps and indeps. If func is a string if must be
% the filename of the function to differentiate. If it is a function
% handle, the name is obtained via which(func2str(func)).
%  
% Both indeps and deps enumerate (comma separated) variable names of
% the parameter and result list of fname, respectively. If indeps
% and/or deps is empty, all variables of the associated list are
% selected.
%
% flags gives additional command-line flags for the admrev system
% command as described in the html-manual of ADiMat provided with this
% installation.
%
% Returns (logical) true on success, false otherwise.
%
% When the function's file is not in the current directory, then
% admrev options -p and -I are used to add the directory to the search
% path for other functions and write the results back to that
% directory.
%  
% When func depends on more functions a searchpath (flag -I <PATH>)
% has to be specified in flags.
%
% Examples: Suppose f is function of x and c and returns y
%
%     function y= f(x,c)
%
% 1. To get the derivative of f with respect to both inputs issue:
%
%       admrev(@f);
%
%    If no errors occured the function g_f is generated in the current
%    directory. To evaluate it do something like:
%
%        y = f(x,c);
%        [a_y]= createFullGradients(y);
%        [a_x, a_c, r]= a_f(x, c, a_y);
%
%    Select a appropiate adjoint class with adimat_adjoint, and a
%    appropiate derivative class, with adimat_derivclass before you
%    run createFullGradients and the function a_f.
%
% 2. To compute the derivative of f with respect to x only, do:
%
%       addiff(@f, 'x');
%
% 3. Supplying a flag to the adimat-client binary is possible, too:
%
%       admTransform(@f, 'x', '', '--verbose=20 -c -c');
%
%    This statement issues some information on the console
%    (--verbose=20) and inserts some comments in the transformed
%    source code (-c -c).
%
% 4. The binary program to be run can be set by the option
%    admtransformProgram or environment variable ADMTRANSFORM_PROGRAM:
%
%       opts = admOptions('admtransformProgram', 'adimat-client');
%
%    or
%
%       setenv('ADMTRANSFORM_PROGRAM', 'adimat-client');
%
% see also admDiffFor, admDiffRev, adimat_derivclass
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
function [success, message] = admTransform(fname, indeps, deps, flags, opts)

  if nargin<1, help admTransform; return; end
  
  if nargin < 2
    [success, message] = admTransform(fname, admOptions());
    return
  end
  
  if nargin > 2 || (nargin > 1 && ~isstruct(indeps))
    if nargin < 5 || isempty(opts)
      opts = admOptions();
    elseif ~isstruct(opts)
      error('adimat:admTransform:fifthArgNotStruct', ...
            'The fifth argument must be empty or a structure');
    end
    if nargin < 4
      flags = '';
    end
    if nargin < 3
      deps = [];
    end
    opts.independents = indeps;
    opts.dependents = deps;
    opts.flags = [opts.flags ' ' flags];
    [success, message] = admTransform(fname, opts);
    return
  end

  if ~isstruct(indeps)
    error('adimat:admTransform:secondArgNotStruct', ...
          'The second argument must be a of type char or a structure');
  end

  opts = indeps;
  
  modeFlag = '';
  if ~isempty(opts.mode)
    modeFlag = ['-' opts.mode ' '];
  elseif ~isempty(opts.toolchain)
    modeFlag = ['-T  ' opts.toolchain];
  end
  if ~isempty(opts.outfile)
    modeFlag = [modeFlag  ' -o ' opts.outfile];
  end

  flags = opts.flags; 

  deps = '';
  if ~isempty(opts.dependents)  
    deps = opts.dependents;
    if ~isa(deps, 'char')
      deps = sprintf('%d,', deps);
    end
    deps = ['-d', deps];
  end

  indeps = '';
  if ~isempty(opts.independents)  
    indeps = opts.independents; 
    if ~isa(indeps, 'char')
      indeps = sprintf('%d,', indeps);
    end
    indeps= ['-i', indeps]; 
  end
  
  if isa(fname, 'function_handle') 
    fname = func2str(fname);
  end
  
  success = 0;
  message = '';

  [fp, fn, fs] = fileparts(fname);
  if isempty(fs)
    fs = '.m';
    ffilename = [fname fs];
  else
    ffilename = fname;
    if ~strcmp(fs, '.m')
      warning('adimat:admTransform:notAnMFile', 'function %s is not a m-file', fname);
    end
  end
  
  if isempty(fp)
    fp = '.';
  end
  
  if ~exist([fp '/' fn fs], 'file')
    fpath = which(ffilename);
  else
    fpath = ffilename;
  end

  if isempty(fpath)
    success = 3;
    error('adimat:admTransform:fileNotFound', ...
          'file containing function %s was not found by which', fname);
  end

  [fp, fn, fs] = fileparts(fpath);
  if ~isempty(fp)
    flags = [flags ' -I ' fp];
    if isempty(strfind([' ' flags], ' -p')) && isempty(strfind([' ' flags], ' --output-dir'))
      flags = [flags ' -p ' fp];
    end
  end

  flags = [flags admBuildFlags(opts.parameters)];

  binaryEnv = getenv('ADMTRANSFORM_PROGRAM');
  binaryOpts = opts.admtransformProgram;
  if ~isempty(binaryOpts)
    binaryName = binaryOpts;
  elseif ~isempty(binaryEnv)
    binaryName = binaryEnv;
  else
    binaryName = [adimat_home(), '/bin/admproc-bin'];
    if ~exist(binaryName, 'file')
      binaryName = [adimat_home(), '/bin/admproc'];
      if ~exist(binaryName, 'file')
        binaryName = [adimat_home() '/bin/adimat-client'];
      end
    end
  end

  flagsEnv = getenv('ADMTRANSFORM_FLAGS');
  if ~isempty(flagsEnv)
    flags = [flags ' ' flagsEnv];
  end

  if ~isempty(strfind(binaryName, 'adimat-client'))
    if exist('admConfirmTransmission') && admConfirmTransmission() == false
      message = 'Permission for sending files denied';
      error('adimat:admTransform:notAllowedToSendFiles', '%s', message);
      return
    end
    flags = [flags ' --interactive=0'];
  end

  depList = admDepList(fpath);
  flags = [flags ' -M "' depList '"'];

  command = ['"', binaryName, '" ', flags, ' ', modeFlag, ...
             ' ', deps, ' ', indeps, ' "', fpath, '"'];

  if exist('matlabroot') && ~ispc
    admwrapEnv = getenv('ADMTRANSFORM_WRAP');
    if ~isempty(admwrapEnv)
      admwrap = admwrapEnv;
    else
      admwrap = [adimat_home(), '/bin/admwrap'];
      command = [admwrap ' -K "' matlabroot '" ' command];
    end
  end

  if admLogLevel > 2 || any(opts.debug)
    fprintf(admLogFile('system'), 'executing command:\n%s\n', command);
  end
  
  if admIsOctave
    command = [command ' 2>&1'];
  end
  
  [stat, msg] = system(command);
  success = ~stat;
  
  fprintf(admLogFile('system'), '%s', msg);
  message = msg;

  if (stat)
    error('adimat:admTransform:system', ...
          'system command: %s failed\nmessage is: %s', ...
          command, message(1:end-1));
  end
  if strfind(msg, 'ERROR') 
    warning('adimat:admTransform:errorsDetected', ...
            'system command: %s\ngenerated ERRORs\nmessage is: %s', ...
            command, message(1:end-1));
  end
  
  resultFunctionName = opts.outfile;
  if isempty(resultFunctionName)
    if ~isempty(opts.mode)
      if opts.mode == 'r'
        resultFunctionName = ['a_', fn];
      elseif opts.mode == 'f'
        resultFunctionName = ['d_', fn];
      elseif opts.mode == 't'
        resultFunctionName = ['t_', fn];
      elseif opts.mode == 'F'
        resultFunctionName = [opts.parameters.funcprefix, fn];
      end
    end
  end
  
  if ~isempty(resultFunctionName)
    admLastOptions(fname, resultFunctionName, opts);
  end

% $Id: admTransform.m 4438 2014-06-04 20:10:15Z willkomm $
