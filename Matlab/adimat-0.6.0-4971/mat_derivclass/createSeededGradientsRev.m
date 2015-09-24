% function varargout = createSeededGradientsRev(seedMatrix, varargin)
%   this simply calls createSeededGradientsFor(seedMatrix', varargin)
%
% see also createFullGradients, createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function varargout = createSeededGradientsRev(seedMatrix, varargin)
  ndd = size(seedMatrix, 1);
  totNumEl = admGetTotalNumel(varargin{:});
  if totNumEl ~= size(seedMatrix, 2)
    error('adimat:opt_derivclass:createSeededGradient', ...
          ['In Reverse Mode (RM), the number of columns of the seed ' ...
           'matrix S must be identical with the total number of ' ...
           'components in the (active) function arguments. However, ' ...
           'admGetTotalNumel(varargin{:}) == %d and size(S, ' ...
           '2) = %d'], totNumEl, size(seedMatrix, 1));
  end
  
  [varargout{1:nargin-1}] = createSeededGradientsFor(seedMatrix .', varargin{:});

% $Id: createSeededGradientsRev.m 4234 2014-05-17 13:39:07Z willkomm $
