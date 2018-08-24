% function [a_a] = a_linsolve1(a_z, a, b, opts?)
%
% Compute adjoint of a in z = linsolve(a, b, opts), linear system
% solving.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm
%
function [a_a] = a_linsolve1(a_z, a, b, varargin)
  [m n] = size(a);

  opts = struct;
  if nargin > 3
    opts = varargin{1};
  else
    opts = struct();
    if m ~= n
      opts.RECT = true;
    end
  end
  if isfield(opts, 'TRANSA') && opts.TRANSA
    t = m;
    m = n;
    n = t;
  end
  broad = m <= n;
  
  aopts = adimat_build_linsolve_adjopts(opts, a);
  
  if broad
    if ~admIsOctave() && m ~= n
      warning('adimat:rev:linsolve:underdetermined_not_supported', ...
              ['The differentiation of linsolve in RM with m(=%d) < n(=%d)'...
               '(underdetermined LS) is not supported in MATLAB.'...
               ' Consider using adimat_sol_qr in your code instead.'], ...
              m, n);
    end
  
    if ~isreal(a)
      % opts.TRANSA will be flipped, but for complex systems we have to
      % conjugate as well
      adj_sys = conj(a);
    else
      adj_sys = a;
    end
    
    z = linsolve(a, b, opts);
    rhs = -a_z * z.';
    a_a = callwo(@linsolve, adj_sys, rhs, aopts);
    if isfield(opts, 'TRANSA') && opts.TRANSA
      a_a = a_a.';
    end
  else

    if isfield(opts, 'TRANSA') && opts.TRANSA
      a = a.';
    end
    [a_a a_b z] = a_adimat_sol_qr(a, b, a_z);
    if isfield(opts, 'TRANSA') && opts.TRANSA
      a_a = a_a.';
    end
  end
% $Id: a_linsolve1.m 4797 2014-10-08 10:37:43Z willkomm $
