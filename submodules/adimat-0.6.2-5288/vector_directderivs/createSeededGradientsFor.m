% function varargout = createSeededGradientsFor(seedMatrix, varargin)
%
% Compute the number ndd = size(seedMatrix, 2) of derivative
% directions and the total number t of components of all n input
% arguments. Check that t == size(seedMatrix, 1). Create n gradient
% objects where each leading dimension of float components represents
% one of the ndd derivative directions. Also store the number ndd with
% option('ndd', ndd).
%
% This function only works with float, cell, or struct objects as
% input. If you have inputs of other type, you have to set
% option('ndd') manually, create zero derivative objects using d_zeros
% and then seed manually, e.g. set the derivative components to the
% components of your seed matrix.
%
% see also createFullGradients, createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function varargout = createSeededGradientsFor(seedMatrix, varargin)
  ndd = size(seedMatrix, 2);
  totNumEl = admTotalNumel(varargin{:});
  if totNumEl ~= size(seedMatrix, 1)
    error('adimat:opt_derivclass:createSeededGradient', ...
          ['In Forward Mode (FM), the number of rows of the seed ' ...
           'matrix S must be identical with the total number of ' ...
           'components in the (active) function arguments. However, ' ...
           'admGetTotalNumel(varargin{:}) == %d and size(S, ' ...
           '1) = %d'], totNumEl, size(seedMatrix, 1));
  end

  [results{1:nargin-1}] = createZeroGradients(ndd, varargin{:});

  estart = 0;
  eend = 0;

  for ai=1:nargin-1
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
      darg = reshape(full(seedMatrix(estart:eend, :).'), [ndd size(arg)]);
    end
    varargout{ai} = darg;
  end

% $Id: createSeededGradientsFor.m 4355 2014-05-28 11:10:28Z willkomm $
