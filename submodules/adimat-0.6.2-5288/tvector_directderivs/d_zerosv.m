% function varargout = d_zerosv(varargin)
%
% Create zero derivatives of input arguments, with the number of
% derivative components given by option('ndd')
%
% see also d_zeros, option, createFullGradients
%
% Copyright 2010-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function varargout = d_zerosv(varargin)
  for i=1:nargin
    varargout{i} = d_zeros(varargin{i});
  end

% $Id: d_zerosv.m 2997 2011-06-21 15:30:11Z willkomm $
