% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;

    if isa(obj, 'arrdercont')
      sz = obj.m_size;
    else
      obj = arrdercont([]);
      sz = obj.m_size;
    end

    if isfloat(rhs) && isequal(size(rhs), [0 0])
      % delete operation

      if length(subs) == 1
        isv = isvector(obj);
        if ~isv
          obj.m_size = [1 prod(obj.m_size)];
          subs = [{':'} subs];
        else
          isr = isrow(obj);
          if isr
            subs = [{':'} subs];
          else
            subs = [subs {':'}];
          end
        end
        obj.m_derivs = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
        obj.m_derivs(subs{:}, ':') = [];
        obj.m_size = computeSize(obj);
      else
        if length(subs) < length(obj.m_size)
          obj.m_size = [obj.m_size(1:length(subs)-1) prod(obj.m_size(length(subs):end))];
        end
        obj.m_derivs = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
        obj.m_derivs(subs{:}, ':') = [];
        obj.m_size = computeSize(obj);
      end
      
      obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
    
    else
    if length(subs) == 1

      if isa(rhs, 'arrdercont')
        rhsd = rhs.m_derivs(:,:);
      else
        rhsd = repmat(rhs(:), [1 obj.m_ndd]);
      end
      
      ind1 = subs{1};

      if isnumeric(ind1)
        numInd1 = numel(ind1);
        maxInd1 = max(ind1(:));
      elseif islogical(ind1)
        numInd1 = sum(ind1(:));
        maxInd1 = numel(ind1);
      else % :
        numInd1 = prod(sz);
        maxInd1 = numInd1;
      end
      
      if isscalar(rhs)
        rhsd = repmat(rhsd, [numInd1 1]);
      end
        
      if maxInd1 > prod(sz)
        % enlarging
        trial = reshape(obj.m_derivs(:, 1), sz);
        trial(ind1) = rhsd(:, 1);
        
        szt = size(trial);
        topind = prod(szt);
        obj.m_derivs(topind, 1) = 0;
        
        obj.m_derivs(ind1, :) = rhsd;
        obj.m_size = szt;
      else
        % not enlarging
        obj.m_derivs(ind1, :) = rhsd;
      end
        
    elseif length(subs) == 2
      % regular, double index
      
      ind1 = subs{1};
      ind2 = subs{2};

      if isa(rhs, 'arrdercont')
        rhsd = reshape(rhs.m_derivs, [rhs.m_size rhs.m_ndd]);
      else
        rhsd = repmat(rhs, [1 1 obj.m_ndd]);
      end

      if isnumeric(ind1)
        numInd1 = numel(ind1);
        maxInd1 = max(ind1(:));
      elseif islogical(ind1)
        numInd1 = sum(ind1(:));
        maxInd1 = numel(ind1);
      else % :
        numInd1 = sz(1);
        maxInd1 = numInd1;
      end

      if isnumeric(ind2)
        numInd2 = numel(ind2);
        maxInd2 = max(ind2(:));
      elseif islogical(ind2)
        numInd2 = sum(ind2(:));
        maxInd2 = numel(ind2);
      else % :
        numInd2 = prod(sz(2:end));
        maxInd2 = numInd2;
      end

      if isscalar(rhs) && prod(sz) > 0
        rhsd = repmat(rhsd, [numInd1 numInd2 1]);
      end
      
      effSize = obj.m_size;
      if length(obj.m_size) > 2
        effSize = [sz(1) prod(sz(2:end))];
      end
      dds = reshape(obj.m_derivs, [effSize obj.m_ndd]);

      if (~isempty(maxInd1) && maxInd1 > sz(1))...
            || (~isempty(maxInd2) && maxInd2 > effSize(2))
        % enlarging
        trial = reshape(obj.m_derivs(:, 1), sz);
        % workaround bug:
        % trial(ind1, ind2) = rhsd(:, :, 1); % does not work
        % in case trial(1, ':') = ...
        trial = subsasgn(trial, ind(1), rhsd(:, :, 1)); % works
        
        szt = size(trial);
        topind1 = prod(szt(1));
        topind2 = prod(szt(2:end));
        dds(topind1, topind2, 1) = 0;
        obj.m_size = szt;
      end

      dds(ind1, ind2, 1:obj.m_ndd) = rhsd;
      obj.m_derivs = reshape(dds, [prod(obj.m_size) obj.m_ndd]);
    
    else
      % length(subs) > 2
      % FIXME: The case with two indices can be generalized to
      % arbitrary number of indices
      
      % This old variant is probably wrong and slow
      obj = subsasgn_old(obj, ind, rhs);
    
    end
    end
   case '{}'
    if length(ind(1).subs) > 1
      error('not allowed')
    end
    ind1 = ind(1).subs{1};
    if length(ind) > 1
      for i=1:length(ind1)
        k = ind1(i);
        dd = admGetDD(obj, k);
        dd = subsasgn(dd, ind(2:end), rhs);
        obj.m_derivs(:, k) = dd(:);
      end
    else
      csz = size(obj);
      rsz = size(rhs);
      if ~isequal(csz, rsz)
        error('adimat:arrdercont:subsasgn:sizeMismatch', ...
              ['when setting a n-times direction, the size must ' ...
               'be the same as the current size (%s), but it is %s'], ...
              mat2str(csz), mat2str(rsz));
      end
      for i=1:length(ind1)
        k = ind1(i);
        obj.m_derivs(:, k) = rhs(:);
      end
    end
    %    end
  end
end
% $Id: subsasgn.m 4969 2015-03-07 14:05:15Z willkomm $
