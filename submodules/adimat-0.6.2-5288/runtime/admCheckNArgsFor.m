% function r = admCheckNArgsFor(functionName, resultFunctionName, ...
%                            nFuncArgs, nActArgs, fNargout, nActResults)
%
% Check whether the amount of function and derivative arguments is OK
% for differentiated function resultFunctionName.
%
% Copyright 2010,2011 Johannes Willkomm, Scientific Computing Group
%                     TU Darmstadt
function r = admCheckNArgsFor(functionName, resultFunctionName, ...
                              nFuncArgs, nActArgs, fNargout, nActResults)
  r = true;
  % check if nargout and nargin are as expected
  nin = nargin(functionName);
  if nFuncArgs > nin
    r = false;
    error('adimat:admDiffFor:wrongNumberOfInputParameters', ...
          ['The number of input parameters of function %s is %d, but %d arguments were given.\n'], ...
          functionName, nin, nFuncArgs);
  end
  ndin = nargin(resultFunctionName);
  if nActArgs + nFuncArgs > ndin
    r = false;
    error('adimat:admDiffFor:wrongNumberOfInputParameters', ...
          ['The number of input parameters of function %s\ncan at most be %d, but is %d.\n'], ...
          resultFunctionName,  nActArgs + nFuncArgs, ndin);
  end
  nout = nargout(functionName);
  if nout < fNargout
    error('adimat:admDiffFor:wrongNumberOfInputParameters', ...
          ['The number of output parameters of function %s is %d, but %d arguments\n' ...
           'were requested in option field nargout.\n'], ...
          functionName, nout, admOpts.nargout);
  end
  ndout = nargout(resultFunctionName);
  % FIXME: here we would like to use ~= instead of >, but when the
  % .nargout field is used we must be more carefull
  if nActResults + fNargout > ndout
    r = false;
    error('adimat:admDiffFor:wrongNumberOfOutputParameters', ...
          ['The number of output parameters of function %s\nshould be at least %d, but is %d.'], ...
          resultFunctionName,  nActResults + nargout(functionName), ndout);
  end
% $Id: admCheckNArgsFor.m 3827 2013-07-24 15:19:52Z willkomm $
