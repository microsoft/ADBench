function gz=g_dummy
%G_DUMMY Creates an empty first order derivative object.
% Shortcut to get a derivative object without typing a lot.
% Beware this derivative object is not really usable. It is
% created for calling set/get() only.
%
% Copyright 2003, 2004 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

gz= adderivsp([], [], 'empty');

