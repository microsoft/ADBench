% function d_res = adimat_d_linsolve(d_val1, val1, d_val2, val2, varargin)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function [d_res res r] = adimat_d_linsolve(d_val1, val1, d_val2, val2, varargin)
  szv1 = size(val1);
  ndd = size(d_val1, 1);
  [res r] = linsolve(val1, val2, varargin{:});
  d_res = d_zeros(res);
  szv2 = size(val2);

  opts = struct;
  if nargin > 4
    opts = varargin{1};
  end
  
  if isfield(opts, 'TRANSA') && opts.TRANSA
    tall = szv1(1) >= szv1(2);
  else
    tall = szv1(1) <= szv1(2);
  end
  
  if tall
    if isfield(opts, 'TRANSA') && opts.TRANSA
      for d=1:ndd
        dd = linsolve(val1, reshape(d_val2(d,:), szv2) - reshape(d_val1(d,:), szv1)' * res, varargin{:});
        d_res(d, :) = dd(:).';
      end
    else
      for d=1:ndd
        dd = linsolve(val1, reshape(d_val2(d,:), szv2) - reshape(d_val1(d,:), szv1) * res, varargin{:});
        d_res(d, :) = dd(:).';
      end
    end
  else
    % z = pinv(a) * b;
    if isfield(opts, 'TRANSA') && opts.TRANSA
      d_val1 = adimat_opdiff_trans(d_val1, val1);
      val1 = val1';
    end
    d_res = d_adimat_sol_qr(d_val1, val1, d_val2, val2);
%    [d_p p] = d_adimat_pinv(d_val1, val1);
%    d_res = adimat_mtimes_dv(d_p, val2) + adimat_mtimes_vd(p, d_val2);
  end
end
% $Id: adimat_d_linsolve.m 4786 2014-10-07 14:24:05Z willkomm $
