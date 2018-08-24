% function [res] = admUseParallel() 
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
%
% This file is part of the ADiMat runtime environment.
%
function [res] = admUseParallel()
  % here we use uigetpref directly since it concerns only MATLAB anyway.

  % uigetpref(GROUP, PREF, TITLE, QUESTION, PREF_CHOICES)
  title = 'Let ADiMat use the Parallel Computing Toolbox';
  question = ['You appear to have installed the Parallel Computing ' ...
              'Toolbox. Shall ADiMat make use of it (i.e. do you ' ...
              'have enough licenses?)'];

  res = uigetpref('adimat', 'use_parallel', title, question, 'yes|no');
  res = strcmp(res, 'yes');
  
% $Id: admUseParallel.m 3909 2013-10-09 09:38:30Z willkomm $
