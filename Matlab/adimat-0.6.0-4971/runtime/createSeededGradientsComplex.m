% function varargout = createSeededGradientsComplex(seedVector, varargin)
%
% see also createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createSeededGradientsComplex(seedVector, varargin)
  if ~isvector(seedVector)
    error('adimat:runtime:createSeededGradientsComplex', ...
          '%s', ['In scalar Complex Variable Mode (CV), the seed matrix must be a' ...
                 ' (column) vector.']);
  end
  ndd = 1;
  if size(seedVector, 2) ~= 1
    warning('adimat:runtime:createSeededGradientsComplex', ...
            ['In scalar Complex Variable (CV), the seed vector should be a' ...
             ' column vector. However, size(S, 2) = %d'], size(seedVector, 2));
  end

  estart = 0;
  eend = 0;

  for ai=1:nargin-1
    arg = varargin{ai};
    darg = arg;
    estart = eend + 1;
    if iscell(arg)
      eend = eend + admTotalNumel(arg);
      [darg{:}] = createSeededGradientsComplex(seedVector(estart:eend), arg{:});
    elseif isstruct(arg)
      fns = fieldnames(darg);
      for k=1:length(fns)
        fields = {arg.(fns{k})};
        estart = eend + 1;
        eend = eend + admTotalNumel(fields{:});
        [darg.(fns{k})] = createSeededGradientsComplex(seedVector(estart:eend), fields{:});
      end
    elseif isfloat(arg)
      if any(imag(darg(:)))
        error('adimat:runtime:createSeededGradientsComplex', ...
              ['All input arguments must be real numbers, but ' ...
               'some components of input argument number %d have non-zero ' ...
               'imaginary part.'], ai);
      end
      if issparse(darg)
        darg = full(darg);
      end
      eend = eend + numel(darg);
      darg = reshape(complex(real(darg(:)), full(seedVector((estart:eend).'))), size(darg));
    else
    end
    varargout{ai} = darg;
  end

% $Id: createSeededGradientsComplex.m 4456 2014-06-10 06:54:44Z willkomm $
