% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;

    if ~isa(obj, 'arrdercont')
      t(subs{:}) = zeros(size(rhs));
      obj = arrdercont(t);
    end
    sz = obj.m_size;

    if isfloat(rhs) && isequal(size(rhs), [0 0])
      % delete operation

      if length(subs) == 1
        isr = isrow(obj);
        isv = isvector(obj);
        if isv
          if isr
            subs = [{':'} subs];
          end
        else
          obj.m_size = [1 prod(obj.m_size)];
          obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
          subs = [{':'} subs];
        end
        obj.m_derivs(:, subs{:}) = [];
        obj.m_size = computeSize(obj);
      else
        if ~admIsOctave
          if length(subs) < length(obj.m_size)
            obj.m_size = [obj.m_size(1:length(subs)-1) prod(obj.m_size(length(subs):end))];
            obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
          end
        end
        obj.m_derivs(:, subs{:}) = [];
        obj.m_size = computeSize(obj);
      end
      
    else
    if length(subs) == 1

      ind1 = subs{1};

      if islogical(ind1)
        numInd1 = sum(ind1(:));
        maxInd1 = numel(ind1);
      elseif ischar(ind1) && isequal(ind1,':')
        numInd1 = prod(sz);
        maxInd1 = numInd1;
      elseif isempty(ind1)
        numInd1 = 0;
        maxInd1 = 0;
      else
        numInd1 = numel(ind1);
        maxInd1 = max(ind1(:));
      end
      
      if isa(rhs, 'arrdercont')
        rhsd = rhs.m_derivs;
        rsz = rhs.m_size;
        risM = length(rsz) == 2;
        if risM && rsz(1) == 1 && rsz(2) == 1
          rhsd = repmat(rhsd, [1 numInd1]);
        end
      else
        rhsd = rhs; % must be scalar
      end
      
      if maxInd1 > prod(sz)
        % enlarging
        trial = reshape(obj.m_derivs(1, :), sz);
        trial(ind1) = rhsd(1, :);
        
        szt = size(trial);
        topinds = mat2cell(szt', ones(length(szt), 1));
        obj.m_derivs(1, topinds{:}) = 0;
        
        obj.m_derivs(:, ind1) = rhsd(:,:);
        obj.m_size = szt;
      else
        % not enlarging
        obj.m_derivs(:, ind1) = rhsd(:,:);
      end
        
    elseif length(subs) >= 2
      % regular, two or more indices
      
      if isa(rhs, 'arrdercont')
        rhsd = rhs.m_derivs;
      else
        rhsd = repmat(reshape(rhs, [1 size(rhs)]), [obj.m_ndd ones(1,length(subs))]);
      end

      if isscalar(rhs)
        for k=1:length(subs)
          indk = subs{k};
          if islogical(indk)
            numInd(k) = sum(indk(:));
          elseif ischar(indk) && isequal(indk,':')
            if k==length(subs) % last one
              numInd(k) = prod(sz(k:end));
            else
              numInd(k) = sz(k);
            end
          elseif isempty(indk)
            numInd(k) = 0;
          else % numeric
            numInd(k) = numel(indk);
          end
        end
        rhsd = repmat(rhsd, [1 numInd]);
      end
      
      dds = obj.m_derivs;
      if isempty(dds), dds = []; end
      dds(1:obj.m_ndd, subs{:}) = rhsd;
      obj.m_derivs = dds;
    
      obj.m_size = computeSize(obj);
    
    else
      % length(subs) > 2
      error('should never happen')
      obj = subsasgn_old(obj, ind, rhs);
    
    end
    end
    
   case '{}'
    if length(ind(1).subs) > 1
      error('multiple indices in {} not allowed');
    end
    ind1 = ind(1).subs{1};
    if length(ind) > 1
      for i=1:length(ind1)
        k = ind1(i);
        dd = admGetDD(obj, k);
        dd = subsasgn(dd, ind(2:end), rhs);
        obj.m_derivs(k, :) = dd(:);
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
        obj.m_derivs(k, :) = rhs(:);
      end
    end
    %    end
   case '.'
    switch ind.subs
     case 'm_ndd'
      obj.m_ndd = rhs;
    end
  end
end
% $Id: subsasgn.m 4781 2014-10-06 21:51:53Z willkomm $
