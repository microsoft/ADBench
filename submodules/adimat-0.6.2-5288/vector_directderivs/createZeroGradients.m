% function [varargout]= createZeroGradients(ndd, varargin)
%
% Save the number ndd with option('ndd', ndd) and create a zero
% gradient object for each input argument, using d_zeros.
%
% This function only works with float, cell, or struct objects as
% input. If you have inputs of other type, you have to set
% option('ndd') manually and create zero derivative objects using
% d_zeros.
%
% see also d_zeros, createFullGradients, createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createZeroGradients(ndd, varargin)

  if nargin-1 ~= nargout
    error('adimat:vector_directderivs:createZeroGradients', ...
          ['The number of realobjects and gradients have to be ' ...
           'equal. However, there are %d inputs (except first arg ndd)'...
           'and %d outputs'], nargin-1, nargout);
  end

  if ~isscalar(ndd)
    error('adimat:vector_directderivs:createZeroGradients', ...
          '%s', ...
          'The first argument (ndd) must be a scalar');
  end
  
  % Set the global option.
  option('ndd', ndd);
  
  % the last test is stolen from spmd_feval, it seems to check for
  % the required Java support
  if ~admIsOctave() && exist('numlabs') && exist('com.mathworks.toolbox.distcomp.pmode.SessionFactory', 'class') && admUseParallel()
    admSetNDDOnLabs(ndd);
  end
  
  for i=1: nargout
    varargout{i} = d_zeros(varargin{i});
  end
  
% $Id: createZeroGradients.m 3909 2013-10-09 09:38:30Z willkomm $
