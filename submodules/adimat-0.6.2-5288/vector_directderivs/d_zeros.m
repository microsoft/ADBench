% function d_z = d_zeros(val)
%
% Create zero derivatives of input argument, with the number of
% derivative components given by option('ndd')
%
% see also option, createFullGradients
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function d_z = d_zeros(aval)
  if iscell(aval)
    d_z = d_cell(aval);
  elseif isstruct(aval)
    d_z = d_struct(aval);
  elseif isempty(aval)
%    d_z = [];
    ndd = option('ndd');
    d_z = zeros([ndd size(aval)]);
  %  elseif isfloat(aval)
  else
    ndd = option('ndd');
    if isempty(ndd)
      error('adimat:vector_directderivs:d_zeros', ...
              '%s', 'd_zeros: the global variable ndd is empty')
    end
    d_z = zeros([ndd size(aval)]);
  end

% $Id: d_zeros.m 3874 2013-09-24 13:15:15Z willkomm $
