% function [t_inv inv] = adimat_taylor_invert(t_x, x)
%
% Compute taylor coefficients of 1 ./ x.
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_inv inv] = adimat_taylor_invert(t_x, x)
  [ndd maxOrder nel] = size(t_x);
  
  inv = 1 ./ x;
  t_inv = zeros(size(t_x));
  
  invr = reshape(inv, [1 1 nel]);
  
  for o=1:maxOrder
    for k=1:o-1
      t_inv(:,o,:) = t_inv(:,o,:) - t_inv(:,k,:) .* t_x(:,o-k,:);
    end
    
    for i=1:ndd
      dd = t_inv(i,o,:) - invr .* t_x(i,o,:);
      t_inv(i,o,:) = dd(:) ./ x(:);
    end
  end
% $Id: adimat_taylor_invert.m 3251 2012-03-26 13:26:27Z willkomm $
