% function [t_log logx] = adimat_taylor_logs(t_x, x, mode)
%
% Compute taylor coefficients of functions log, log2, log10, and log1p.
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_log logx] = adimat_taylor_logs(t_x, x, mode)
  [ndd maxOrder nel] = size(t_x);
  szt = [1 1 nel];

  factor = 1;
  u0 = x;
  switch mode
   case 'log2'
    logx = log2(x);
    factor = log(2);
   case 'log10'
    logx = log10(x);
    factor = log(10);
   case 'log'
    logx = log(x);
   case 'log1p'
    logx = log1p(x);
    u0 = u0 + 1;
  end
  
  t_log = t_x;

  logxr = reshape(factor .* u0, [1 1 nel]);
  logxr = repmat(logxr, [ndd 1 1]);
  
  for o=1:maxOrder
    sum2 = o .* t_x(:,o,:);
    for k=1:o-1
      sum2 = sum2 - factor .* k .* t_x(:,o-k,:) .* t_log(:,k,:);
    end
    t_log(:, o, :) = sum2 ./ (o.*logxr);
  end

% $Id: adimat_taylor_logs.m 3251 2012-03-26 13:26:27Z willkomm $
