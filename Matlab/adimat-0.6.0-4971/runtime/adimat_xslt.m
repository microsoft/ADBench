%
% function r = adimat_xslt(xsltProg, xsltMode?)
%
% get/set The XSLT processor used by the admproc program. The xsltProg
% is the name of the program to execute. xsltMode specifies the
% command line syntax. This latter currently has no effect.
%
% This feature is implemented by reading/setting the environment
% variable ADIMAT_XSLT.
%
% adimat_xslt('xsltproc')
%   - this sets the XSLT processor.
%
% adimat_xslt()
%   - this returns the current value
%
% see also adimat_stack, adimat_stack_verbosity, adimat_aio_init
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_xslt(xsltProg, xsltMode)
  envVarName1 = 'ADIMAT_XSLT';
  if nargin > 0
    setenv(envVarName1, xsltProg);
  end
  r = getenv(envVarName1);
end

% $Id: adimat_xslt.m 2537 2011-01-21 16:41:49Z willkomm $
