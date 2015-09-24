% function varargout = createSeededGradientsDD(seedVector, varargin)
%
% see also createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment, and belongs
% to the scalar_directderivs derivative "class".
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createSeededGradientsDD(seedVector, varargin)
  if ~isvector(seedVector)
    error('adimat:runtime:createSeededGradientsDD', ...
          '%s', ['In Finite Differences Mode (FD), the seed matrix must be a' ...
                 ' (column) vector.']);
  end
  if isrow(seedVector)
    warning('adimat:runtime:createSeededGradientsDD', ...
            ['In Finite Differences Mode (FD), the seed vector should be a' ...
             ' column vector. However, size(S, 2) = %d'], size(seedVector, 2));
  end

  estart = 0;
  eend = 0;

  nargs = length(varargin);
  
  varargout = varargin;
  
  if nargs == 1
    arg = varargin{1};
    if iscell(arg)
      [arg{:}] = createSeededGradientsDD(seedVector, arg{:});
    elseif isstruct(arg)
      fns = fieldnames(arg);
      for k=1:length(fns)
        fields = {arg.(fns{k})};
        estart = eend + 1;
        eend = eend + admTotalNumel(fields{:});
        [arg.(fns{k})] = createSeededGradientsDD(seedVector(estart:eend), fields{:});
        end
    else
      arg = reshape(arg(:) + seedVector, size(arg));
    end
    varargout{1} = arg;
  else
    for ai=1:nargin-1
      arg = varargin{ai};
      estart = eend + 1;
      if iscell(arg)
        eend = eend + admTotalNumel(arg);
        [arg{:}] = createSeededGradientsDD(seedVector(estart:eend), arg{:});
      elseif isstruct(arg)
        fns = fieldnames(arg);
        for k=1:length(fns)
          fields = {arg.(fns{k})};
          estart = eend + 1;
          eend = eend + admTotalNumel(fields{:});
          [arg.(fns{k})] = createSeededGradientsDD(seedVector(estart:eend), fields{:});
        end
      elseif isfloat(arg)
        eend = eend + numel(arg);
        arg = reshape(arg(:) + seedVector((estart:eend).'), size(arg));
      else
      end
      varargout{ai} = arg;
    end
  end

% $Id: createSeededGradientsDD.m 4456 2014-06-10 06:54:44Z willkomm $
