% function r = adimat_opdiff_subsasgn(d_val, sel, rhs)
%
% Copyright 2011,2014 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val = adimat_opdiff_subsasgn(d_val, sel, rhs)
  last = sel(end);
  if ~strcmp(last.type, '()')
    d_val = subsasgn(d_val, sel, rhs);
  else
    if isstruct(rhs)
      if isempty(d_val)
        d_val = repmat(struct(), 0, 0);
      end
      d_val = subsasgn(d_val, sel, rhs);
    else
      % last is ()-index

      if length(sel) > 1
        d_val_in = d_val;
        try 
          d_val = subsref(d_val, sel(1:end-1));
        catch
          d_val = [];
        end
      end

      rsz = size(rhs); rsz = rsz(2:end);
      if length(rsz) == 1, rsz = [rsz 1]; end
      if isempty(d_val)
        trial = subsasgn([], last, reshape(rhs(1,:), rsz));
        d_val = d_zeros(trial);
        osz = size(trial);
      else
        osz = size(d_val); osz = osz(2:end);
      end
      
      subs = sel(end).subs;

      if length(subs) == 1
        
        ind1 = subs{1};
        
        if isnumeric(ind1)
          numInd1 = numel(ind1);
          maxInd1 = max(ind1(:));
        elseif islogical(ind1)
          numInd1 = sum(ind1(:));
          maxInd1 = numel(ind1);
        else % :
          numInd1 = prod(osz);
          maxInd1 = numInd1;
        end
        
        risM = length(rsz) <= 2;
        if risM && prod(rsz) == 1
          rhs = repmat(rhs, [1 numInd1]);
        end
        
        if maxInd1 > prod(osz)
          % enlarging
          if length(osz) == 1, osz = [osz 1]; end
          trial = reshape(d_val(1, :), osz);
          trial(ind1) = rhs(1, :);
          
          szt = size(trial);
          switch length(szt) 
           case 2
            d_val(1, szt(1), szt(2)) = 0;
           case 3
            d_val(1, szt(1), szt(2), szt(3)) = 0;
           case 4
            d_val(1, szt(1), szt(2), szt(3), szt(4)) = 0;
           otherwise
            topinds = mat2cell(szt', ones(length(szt), 1));
            d_val(1, topinds{:}) = 0;
          end
          
          d_val(:, ind1) = rhs(:,:);
        else
          % not enlarging
          d_val(:, ind1) = rhs(:,:);
        end
        
      elseif length(subs) == 2
        % regular, double index
        
        ind1 = subs{1};
        ind2 = subs{2};
        
        if isnumeric(ind1)
          numInd1 = numel(ind1);
        elseif islogical(ind1)
          numInd1 = sum(ind1(:));
        else % :
          numInd1 = osz(1);
        end
        
        if isnumeric(ind2)
          numInd2 = numel(ind2);
        elseif islogical(ind2)
          numInd2 = sum(ind2(:));
        else % :
          numInd2 = prod(osz(2:end));
        end
        
        if prod(rsz) == 1
          rhs = repmat(rhs, [1 numInd1 numInd2]);
        end
      
        d_val(1:size(d_val, 1), ind1, ind2) = rhs;
        
      else
        % length(subs) > 2

        d_val = adimat_opdiff_subsasgn_old(d_val, sel, rhs);
        
      end
      
    end

    % last is ()-index
    if length(sel) > 1
      d_val = subsasgn(d_val_in, sel(1:end-1), d_val);
    end

  end
  
% $Id: adimat_opdiff_subsasgn.m 4963 2015-03-03 11:56:24Z willkomm $
