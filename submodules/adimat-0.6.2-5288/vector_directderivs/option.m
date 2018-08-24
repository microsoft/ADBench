% function r = option(name, val?)
%   This function manages options of the vector_directderivs
%   derivative objects. Options can be queried using
%   option(name). Options can be set using option(name, value). When
%   setting an option the previous value will be returned.
%
%   option('ndd')
%   option('ndd', newNDD)
%      The number of directional derivatives. This option value is
%      needed by the function d_zeros to create derivative objects
%      with the right number of components. This options is usually
%      set automagically when createFullGradients is called.
%
%   option('NumberOfDirectionalDerivatives')
%   option('NumberOfDirectionalDerivatives', newNDD)
%      The same as above.
%
%   option('?')
%      Return list of available options in a cell array.
%
% see also d_zeros, createFullGradients
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
function r = option(name, val)
  persistent ndd
  
  if nargin == 1
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      r = ndd;
     case {'?'}
      r = {'ndd'; 'NumberOfDirectionalDerivatives'};
    end
  else
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      r = ndd;
      ndd = val;
    end
  end

