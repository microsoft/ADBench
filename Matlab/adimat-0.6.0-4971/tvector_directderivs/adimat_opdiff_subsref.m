%
% function r = adimat_diff_subsref(d_val, sel)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_subsref(d_val, sel)
  r = d_val;
  last = sel(end);
  if last.type == '()'
    if length(sel) > 1
      r = subsref(r, sel(1:end-1));
    end
    if isa(r, 'struct')
      r = r(last.subs{:});
    else
      sz = size(r);
      args = last.subs;
      singleIndNotWild = length(args) == 1 && ~(isa(args{1}, 'char') && strcmp(args{1}, ':'));
      if length(sz) > 2 && sz(2) == 1 && sz(3) > 1 && singleIndNotWild && length(size(args{1})) == 1 
        r = r(:, :, :, args{:});
      else
        r = r(:, :, args{:});
        if singleIndNotWild && ~islogical(args{1}) && length(size(args{1})) > 1
          r = reshape(r, [sz(1) sz(2) size(args{1})]);
        end
      end
    end
  else
    r = subsref(r, sel);
  end

% $Id: adimat_opdiff_subsref.m 3343 2012-07-24 16:15:16Z willkomm $
