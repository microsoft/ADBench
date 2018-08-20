function num = admGetNDD(g_obj)
% GETNDD -- Get the (current) number directional derivatives.
%
% Copyright (c) 2018 Johannes Willkomm
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  if nargin < 1
    g_obj = g_dummy();
  end
  num = get(g_obj, 'ndd');
