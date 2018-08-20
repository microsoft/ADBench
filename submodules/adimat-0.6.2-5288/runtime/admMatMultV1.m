% function Z = admMatMultV1(A, B)
%
% Multiply A * B for tensors, with the surplus dimension being the
% first.
%
% A and B may both be tensors, or just A, or just B.
%
% This function is a reference implementation to test the more
% efficient variants, admMatMultV1MT, admMatMultV1TM, and
% admMatMultV1TT.
%
% see also admMatMultV1MT, admMatMultV1TM, admMatMultV1TT,
% admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1(A, B)
  
  if ndims(A) > 2 && ndims(B) > 2
    
    Z = admMatMultV1TT(A, B);
  
  elseif ndims(A) > 2

    Z = admMatMultV1TM(A, B);
  
  else

    Z = admMatMultV1MT(A, B);
  
  end

% $Id: admMatMultV1.m 4474 2014-06-12 08:31:02Z willkomm $
