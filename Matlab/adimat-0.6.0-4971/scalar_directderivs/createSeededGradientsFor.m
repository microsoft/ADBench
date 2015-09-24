% function varargout = createSeededGradientsFor(seedVector, varargin)
%
% see also createFullGradients, createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createSeededGradientsFor(seedVector, varargin)
  if ~iscolumn(seedVector)
    error('adimat:scalar_directderivs:createSeededGradient', ...
          '%s', ['In scalar Forward Mode (FM), the seed matrix must be a' ...
                 ' column vector.']);
  end
  
  varargout = cell(nargout, 1);

  if nargout == 1
    varargout{1} = reshape(full(seedVector), size(varargin{1}));
  else
    estart = 0;
    eend = 0;
    
    for ai=1:nargin-1
      arg = varargin{ai};
      estart = eend + 1;
      eend = eend + numel(arg);
      darg = reshape(full(seedVector(estart:eend)), size(arg));
      varargout{ai} = darg;
    end
  
  end
