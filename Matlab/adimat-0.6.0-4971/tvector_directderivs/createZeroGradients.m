% function [varargout]= createZeroGradients(maxOrder, ndd, varargin)
%
% Save the number maxOrder with option('order', maxOrder) and the
% number ndd with option('ndd', ndd) and create a zero gradient object
% for each input argument, using d_zeros.
%
% see also d_zeros, createFullGradients, createSeededGradientsFor
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [varargout]= createZeroGradients(maxOrder, ndd, varargin)

  if nargin-2 ~= nargout
    error('adimat:vector_directderivs:createZeroGradients', ...
          ['The number of realobjects and gradients have to be ' ...
           'equal. However, there are %d inputs (except first arg ndd)'...
           'and %d outputs'], nargin-2, nargout);
  end

  if ~isscalar(maxOrder)
    error('adimat:tvector_directderivs:createZeroGradients', ...
          '%s', ...
          'The first argument (maxOrder) must be a scalar');
  end
  
  if ~isscalar(ndd)
    error('adimat:tvector_directderivs:createZeroGradients', ...
          '%s', ...
          'The second argument (ndd) must be a scalar');
  end
  
  % Set the global option.
  option('ndd', ndd);
  option('order', maxOrder);
  
  for i=1: nargout
    varargout{i} = t_zeros(varargin{i});
  end
  
% $Id: createZeroGradients.m 3198 2012-03-09 12:00:11Z willkomm $
