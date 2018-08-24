% function z = admMatMultV3(A, B)
%
% Multiply A * B for tensors, with the surplus dimension being the
% third.
%
% A and B may both be tensors, or just A, or just B.
%
% This function is a reference implementation to test the more
% efficient variants, admMatMultV3MT, admMatMultV3TM, and
% admMatMultV3TT.
%
% see also admMatMultV3MT, admMatMultV3TM, admMatMultV3TT,
% admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function z = admMatMultV3(A, B)
  
  if ndims(A) > 2 && ndims(B) > 2
    n = size(A, 3);
    z = zeros(size(A, 1), size(B, 2), n);
    for i=1:n
      z(:,:,i) = A(:,:,i) * B(:,:,i);
    end
  
  elseif ndims(A) > 2
    n = size(A, 3);
    z = zeros(size(A, 1), size(B, 2), n);
    for i=1:n
      z(:,:,i) = A(:,:,i) * B;
    end
  
  else
    n = size(B, 3);
    z = zeros(size(A, 1), size(B, 2), n);
    for i=1:n
      z(:,:,i) = A * B(:,:,i);
    end
  
  end

% $Id: admMatMultV3.m 4467 2014-06-11 10:44:59Z willkomm $
