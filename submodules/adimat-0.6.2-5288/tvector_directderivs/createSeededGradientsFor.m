% function varargout = createSeededGradientsFor(maxOrder, seedMatrix, varargin)
%
% see also createFullGradients, createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function varargout = createSeededGradientsFor(maxOrder, seedMatrix, varargin)
  ndd = size(seedMatrix, 2);
  totNumEl = admTotalNumel(varargin{:});
  if totNumEl ~= size(seedMatrix, 1)
    error('adimat:tvector_directderivs:createSeededGradient', ...
          ['In Forward Mode (FM), the number of rows of the seed ' ...
           'matrix S must be identical with the total number of ' ...
           'components in the (active) function arguments. However, ' ...
           'admGetTotalNumel(varargin{:}) == %d and size(S, ' ...
           '1) = %d'], totNumEl, size(seedMatrix, 1));
  end

  [results{1:nargin-2}] = createZeroGradients(maxOrder, ndd, varargin{:});

  estart = 0;
  eend = 0;

  for ai=1:nargin-2
    arg = varargin{ai};
    darg = results{ai};
    estart = eend + 1;
    if iscell(arg)
      eend = eend + admTotalNumel(arg);
      [darg{:}] = createSeededGradientsFor(seedMatrix(estart:eend, :), arg{:});
    elseif isstruct(arg)
      fns = fieldnames(darg);
      for k=1:length(fns)
        fields = {arg.(fns{k})};
        estart = eend + 1;
        eend = eend + admTotalNumel(fields{:});
        [darg.(fns{k})] = createSeededGradientsFor(seedMatrix(estart:eend, :), fields{:});
      end
    elseif isempty(arg)
      % do nothing
    elseif isfloat(arg)
      eend = eend + admTotalNumel(arg);
      for i=1:ndd
        darg(i, 1, :) = seedMatrix(estart:eend, i);
      end
    end
    varargout{ai} = darg;
  end

% $Id: createSeededGradientsFor.m 3198 2012-03-09 12:00:11Z willkomm $
