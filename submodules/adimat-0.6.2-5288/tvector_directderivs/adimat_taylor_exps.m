% function [t_exp expx] = adimat_taylor_exps(t_x, x, mode)
%
% Compute taylor coefficients of functions exp, pow2, and expm1.
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_exp expx] = adimat_taylor_exps(t_x, x, mode)
  [ndd maxOrder nel] = size(t_x);

  factor = 1;
  switch mode
   case 'exp'
    expx = exp(x);
   case 'exp2'
    expx = pow2(x);
    factor = log(2);
%   case 'exp10'
%    expx = exp10(x);
%    factor = log(10);
   case 'expm1'
    expx = expm1(x);
  end
  
  expxr = reshape(expx, [1 1 nel]);
  expxr = repmat(expxr, [ndd 1 1]);
  if strcmp(mode, 'expm1')
    expxr = expxr + 1;
  end
  
  t_exp = zeros(size(t_x));

  for o=1:maxOrder
    for k=1:o-1
      t_exp(:,o,:) = t_exp(:,o,:) + k .* t_exp(:,o-k,:) .* t_x(:,k,:);
    end
    t_exp(:,o,:) = t_exp(:,o,:) + o .* expxr .* t_x(:,o,:);
    t_exp(:,o,:) = t_exp(:,o,:) .* (factor ./ o);
  end

% $Id: adimat_taylor_exps.m 3251 2012-03-26 13:26:27Z willkomm $
