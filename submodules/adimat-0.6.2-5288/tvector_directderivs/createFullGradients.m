% function [varargout]= createFullGradients(maxOrder, varargin)
%
% see also d_zeros, option, createSeededGradientsFor
%
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [varargout]= createFullGradients(maxOrder, varargin)
  if nargin ~= nargout+1
    error('adimat:vector_derivclass:createFullGradients', ...
          'createFullGradients: %s', ...
          'The number of input and output arguments have to be equal.');
  end
  
  ndd = admTotalNumel(varargin{:});
  
  seedMatrix = speye(ndd);
  
  [varargout{1:nargout}] = createSeededGradientsFor(maxOrder, seedMatrix, varargin{:});
