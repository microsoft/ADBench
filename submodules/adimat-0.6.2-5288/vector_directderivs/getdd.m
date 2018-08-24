%
% function [derivative] = getdd(obj, index)
%   get the derivative directions ind from derivative object obj
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = getdd(obj, i)
  if nargin < 2
    i = 1:size(obj,1);
  end
  nd = numel(i);
  sz = size(obj);
  data = obj(i, :);
  switch nd
   case 1
    r = reshape(data, sz(2:end));
   otherwise
    % also if nd == 0
    r = reshape(data, [nd sz(2:end)]);
  end
  