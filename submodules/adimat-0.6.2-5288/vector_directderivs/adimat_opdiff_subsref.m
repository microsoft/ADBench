% function r = adimat_diff_subsref(d_val, sel)
%
% Copyright 2011-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val = adimat_opdiff_subsref(d_val, sel)
  last = sel(end);
  if last.type == '()'
    if length(sel) > 1
      d_val = subsref(d_val, sel(1:end-1));
    end
    if ~isnumeric(d_val)
      % struct or cell
      r = r(last.subs{:});
    else
      sz = size(d_val); 
      osz = sz(2:end);
      args = last.subs;
      d_val = d_val(:, args{:});
      
      if length(args) == 1
        ind1 = args{1};
        isM = length(osz) <= 2;
        if isnumeric(ind1)
          numInd1 = numel(ind1);
          if isM && osz(1) == 1 && isvector(ind1)
            rsz = [1, numInd1];
          elseif isM && (length(osz) < 2 || osz(2) == 1) && isvector(ind1)
            rsz = [numInd1, 1];
          else
            rsz = size(ind1);
          end
        elseif islogical(ind1)
          numInd1 = sum(ind1(:));
          if isM && osz(1) == 1
            rsz = [1, numInd1];
          else
            rsz = [numInd1, 1];
          end
        else % :
          numInd1 = prod(osz);
          rsz = [numInd1, 1];
        end
      
        d_val = reshape(d_val, [size(d_val, 1) rsz]);
      end
      
    end
  else
    r = subsref(r, sel);
  end

% $Id: adimat_opdiff_subsref.m 4362 2014-05-28 11:20:16Z willkomm $
