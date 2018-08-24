% function t_z = t_zeros(aval)
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

function d_z = t_zeros(aval)
  if iscell(aval)
    d_z = d_cell(aval);
  elseif isstruct(aval)
    d_z = d_struct(aval);
  elseif isempty(aval)
    d_z = [];
  %  elseif isfloat(aval)
  else
    ndd = option('ndd');
    nord = option('order');
    if isempty(ndd)
      error('adimat:vector_directderivs:d_zeros', ...
              '%s', 'd_zeros: the global variable ndd is empty')
    end
    if isempty(nord)
      error('adimat:vector_directderivs:d_zeros', ...
              '%s', 'd_zeros: the global variable order is empty')
    end
    d_z = zeros([ndd nord size(aval)]);
  end

% $Id: t_zeros.m 3223 2012-03-16 09:58:33Z willkomm $
