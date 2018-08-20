% function varargout = createSeededGradientsFor(seedMatrix, varargin)
%
% see also createFullGradients, createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function varargout = createSeededGradientsFor(seedMatrix, varargin)
  ndd = size(seedMatrix, 2);
  totNumEl = admGetTotalNumel(varargin{:});
  if totNumEl ~= size(seedMatrix, 1)
    error('adimat:opt_derivclass:createSeededGradients', ...
          ['In Forward Mode (FM), the number of rows of the seed ' ...
           'matrix S must be identical\nwith the total number of ' ...
           'components in the (active) function arguments.\nHowever, ' ...
           'admGetTotalNumel(varargin{:}) == %d and size(S, ' ...
           '1) = %d'], totNumEl, size(seedMatrix, 1));
  end

  [varargout{1:nargin-1}] = createZeroGradients(ndd, varargin{:});

  if nargin == 2
    varargout{1} = set(varargout{1}, 'deriv', full(seedMatrix));
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
    darg = varargout{ai};
    estart = eend + 1;
    eend = eend + numel(arg);
    darg = set(darg, 'deriv', full(seedMatrix(estart:eend, :)));
    varargout{ai} = darg;
  end
  end

% $Id: createSeededGradientsFor.m 4475 2014-06-12 08:31:27Z willkomm $
