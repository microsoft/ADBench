%
% function [derivative] = getdd(obj, index)
%   get the derivative directions ind from derivative object obj
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function varargout = getdd(obj, i)
  if nargin < 2
    i = 1:get(obj, 'ndd')
  end
  varargout = {obj{i}};
