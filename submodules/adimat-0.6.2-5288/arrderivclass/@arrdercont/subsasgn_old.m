% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = subsasgn_old(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;
    dind = ind;
    if ~(length(subs) == 1 && ischar(subs{1}) && ischar(subs{1}) && isequal(subs{1}, ':'))
      dind(1).subs = {':', subs{:}};
    end
    if isa(rhs, 'arrdercont')
      ndd = rhs.m_ndd;
      rhsderivs = rhs.m_derivs;
      szr = size(rhs);
      szl = size(obj);
      szo = szl;
      if isempty(obj) && isa(obj, 'double')
        obj = arrdercont([]);
        ddr = reshape(rhsderivs(1,:), szr);
        ddl = subsasgn([], ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        obj.m_derivs = zeros([ndd szl]);
      else
        ddl = reshape(obj.m_derivs(1,:), szl);
        ddr = reshape(rhsderivs(1,:), szr);
        ddl = subsasgn(ddl, ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        if any(szl > szo)
          topind = mat2cell(szl, 1, ones(1, length(szl)));
          obj.m_derivs(1, topind{:}) = ddl(topind{:});
        end
      end
      szl = size(obj);
      for i=1:ndd
        ddl = reshape(obj.m_derivs(i,:), szl);
        ddr = reshape(rhs.m_derivs(i,:), szr);
        ddl = subsasgn(ddl, ind, ddr);
        obj.m_derivs(i,:) = ddl(:).';
      end
    else
      if isscalar(rhs)
        testobj = subsasgn(zeros(size(obj)), ind, 1);
        nass = sum(testobj(:));
        rhs = repmat(rhs, [1 nass 1]);
      end
      rhs = repmat(reshape(rhs, [1 size(rhs)]), [obj.m_ndd ones(1, length(size(rhs)))]);
      obj.m_derivs = subsasgn(obj.m_derivs, dind, rhs);
    end
    obj.m_size = computeSize(obj);
    varargout{1} = obj;
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
  end
end
% $Id: subsasgn_old.m 4239 2014-05-17 16:32:58Z willkomm $
