% function [g_z z] = adimat_g_linsolve(g_a, a, g_b, b, ops)
%
% Compute derivative of z = linsolve(a, b, opts), linear system
% solving, similar to matrix left division. Also return the function
% result z.
%
% see also adimat_g_mldivide
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z r] = adimat_g_linsolve(g_a, a, g_b, b, varargin)

  [m n] = size(a);
  
  [z r] = linsolve(a, b, varargin{:});

  opts = struct;
  if nargin > 4
    opts = varargin{1};
  end
  if isfield(opts, 'TRANSA') && opts.TRANSA
    broad = m >= n;
  else
    broad = m <= n;
  end
  
  if broad
    if isfield(opts, 'TRANSA') && opts.TRANSA
      rhs = g_b - g_a' * z;
    else
      rhs = g_b - g_a * z;
    end
    g_z = call(@(x) linsolve(a, x, varargin{:}), rhs);
  else  
    % z = pinv(a) * b;
    if isfield(opts, 'TRANSA') && opts.TRANSA
      g_a = g_a'; a = a';
    end
    g_z = g_adimat_sol_qr(g_a, a, g_b, b);
%    [g_p p] = g_adimat_pinv(g_a, a);
%    g_z = g_p * b + p * g_b;
  end

% $Id: adimat_g_linsolve.m 4786 2014-10-07 14:24:05Z willkomm $
