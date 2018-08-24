function gz=h_dummy
%H_DUMMY Creates an empty second order derivative object.
% For internal use only. Do not mess with this function.
%
% Copyright 2003, 2004 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

ndd= get(adderiv([],[],'empty'), 'NumberOfDirectionalDerivatives');

if length(ndd)==1
  ndd= [ndd ndd];
end

gz= adderiv(ndd, [], 'empty');

