% function [varargout]= createFullGradients(varargin)
%
% Compute the total number ndd of components of all n input arguments
% and create n gradient objects where each leading dimension of float
% components represents one of the ndd derivative directions. Also
% store the number ndd with option('ndd', ndd).
%
% This function only works with float, cell, or struct objects as
% input. If you have inputs of other type, you have to set
% option('ndd') manually, create zero derivative objects using d_zeros
% and then seed manually, e.g. set some derivative components to one.
%
% see also d_zeros, option, createSeededGradientsFor
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [varargout]= createFullGradients(varargin)
  if nargin~= nargout
    error('adimat:vector_derivclass:createFullGradients', ...
          'createFullGradients: %s', ...
          'The number of input and output arguments have to be equal.');
  end
  
  ndd = admTotalNumel(varargin{:});
  option('ndd', ndd);
  
  c_ndd = 1;
  for k=1:nargin
    arg = varargin{k};
    darg = zeros([ndd, size(arg)]);

    for i=1:numel(arg)
      darg(c_ndd, i) = 1;
      c_ndd = c_ndd + 1;
    end
    
    varargout{k} = darg;
  end
  
