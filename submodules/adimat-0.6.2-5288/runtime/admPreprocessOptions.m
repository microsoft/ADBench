% function opts = admCheckOptions(opts)
%
% Preprocess admOptions opts fields, expanding meta fields
%
% see also admOptions, admStackOptions, admTransformParameters
%
% Copyright (C) 2014,2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
% This file is part of the ADiMat runtime environment.
%
function opts = admPreprocessOptions(opts)
  
  if opts.nochecks
    opts.forceTransform = -1;
    opts.checkDependencies = false;
    opts.checkResultSizes = false;
    opts.checknargs = false;
    opts.checkoptions = false;
  end
  if ~iscell(opts.functionResults)
    opts.functionResults = {opts.functionResults};
  end
