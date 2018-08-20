% function varargout = createSeededGradientsFor(seedMatrix, varargin)
%
% see also createFullGradients, createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function varargout = createSeededGradientsFor(seedMatrix, varargin)
  ndd = size(seedMatrix, 2);

  [varargout{1:nargin-1}] = createZeroGradients(ndd, varargin{:});

  if nargin == 2
    varargout{1} = set(varargout{1}, 'deriv', reshape(full(seedMatrix).', [ndd size(varargin{1})]));
  else
  estart = 0;
  eend = 0;

  for ai=1:nargin-1
    arg = varargin{ai};
    if ~isfloat(arg)
      error('adimat:opt_derivclass:createSeededGradients', ...
            ['Independent parameters, and arguments to ' ...
             'createSeededGradients, must all be float, but argument %d ' ...
             'has class: %s'], ai+1, class(arg));
    end
    estart = eend + 1;
    eend = eend + numel(arg);
    varargout{ai} = set(varargout{ai}, 'deriv', reshape(full(seedMatrix(estart:eend, :)).',[ndd size(arg)]));
  end
  end

% $Id: createSeededGradientsFor.m 4450 2014-06-10 06:49:22Z willkomm $
