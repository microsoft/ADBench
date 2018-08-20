function sz=objsize(g)
%ADDERIV/GET Get the size of object that the derivative is associated with.
%
%  sz = size(g); Gets the 0-th directional derivative of the 
%       first order derivative object g and returns the size of it.
%       
%       This means that size(g_x) has the same result as size(x).
%
% Copyright 2009 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%

sz = get(g, 'ObjSize');

