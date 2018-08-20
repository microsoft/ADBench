%ADDERIV/LENGTH Get the length of object that the derivative is associated with.
%
%       This function returns max(size(g))
%
% see also adderiv/size
%
% Copyright 2009 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
function res = length(g)
  res = max(size(g));
end  
