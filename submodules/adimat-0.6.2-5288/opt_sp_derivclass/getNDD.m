function num= getNDD()
% GETNDD -- Get the (current) number directional derivatives.
%   num= getNDD()
%   Fetches the number of directional derivatives from the
%   global variable numberofDirectionalDerivatives, where
%   the constructor function createEmptyGradients stored the
%   number.
% 
% OBSOLETE !!!
% This function is obsolete and will be discarded soon.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

num= get(adderiv([],[],'empty'), 'NumberOfDirectionalDerivatives');
warning('ADiMat:getNNDwarning', 'getNDD() will be discarded in the near future! Use get(g_dummy, ',39,'NumberOfDirectionalDerivatives',39,') instead.');

