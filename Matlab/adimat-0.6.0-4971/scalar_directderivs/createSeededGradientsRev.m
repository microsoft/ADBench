% function varargout = createSeededGradientsFor(seedVector, varargin)
%
% see also createFullGradients, createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createSeededGradientsRev(seedVector, varargin)
  if ~isrow(seedVector)
    error('adimat:scalar_directderivs:createSeededGradient', ...
          '%s', ['In scalar Reverse Mode (RM), the seed matrix must be a' ...
                 ' row vector.']);
  end
  [varargout{1:nargin-1}] = createSeededGradientsFor(seedVector .', varargin{:});

