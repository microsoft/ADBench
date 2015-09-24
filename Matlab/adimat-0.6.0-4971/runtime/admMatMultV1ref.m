% function z = admMatMultV1(A, B)
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
function z = admMatMultV1ref(A, B)
  
  if ndims(A) > 2 && ndims(B) > 2
    n = size(A, 1);
    z = zeros(size(A, 1), size(A, 2), size(B, 3));
    for i=1:n
      z(i,:,:) = shiftdim(A(i,:,:),1) * shiftdim(B(i,:,:),1);
    end
  
  elseif ndims(A) > 2
    n = size(A, 1);
    z = zeros(size(A, 1), size(A, 2), size(B, 2));
    for i=1:n
      z(i,:,:) = shiftdim(A(i,:,:),1) * B;
    end
  
  else
    n = size(B, 1);
    z = zeros(size(B, 1), size(A, 1), size(B, 3));
    for i=1:n
      z(i,:,:) = A * shiftdim(B(i,:,:),1);
    end
  
  end

% $Id: admMatMultV1ref.m 4558 2014-06-15 18:21:07Z willkomm $
