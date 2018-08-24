% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = subsasgn_old(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;
    dind = ind;
    dind(1).subs = [ subs {':'}];
    if isa(rhs, 'arrdercont')
      ndd = rhs.m_ndd;
      rhsderivs = rhs.m_derivs;
      szr = size(rhs);
      szl = size(obj);
      szo = szl;
      if isempty(obj) && isa(obj, 'double')
        obj = arrdercont([]);
        ddr = reshape(rhsderivs(:,1), szr);
        ddl = subsasgn([], ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        obj.m_derivs = zeros([prod(szl) ndd]);
      else
        ddl = reshape(obj.m_derivs(:,1), szl);
        ddr = reshape(rhsderivs(:,1), szr);
        ddl = subsasgn(ddl, ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        if any(szl > szo)
          topind = prod(szl);
          obj.m_derivs(topind, 1) = 0;
        end
      end
      for i=1:ndd
        ddl = reshape(obj.m_derivs(:,i), szl);
        ddr = reshape(rhs.m_derivs(:,i), szr);
        ddl = subsasgn(ddl, ind, ddr);
        obj.m_derivs(:,i) = ddl(:);
      end
    else
      testobj = subsasgn(zeros(size(obj)), ind, 1);
      if isscalar(rhs)
        nass = sum(testobj(:));
        rhs = repmat(rhs, [nass 1]);
      end
      rhs = repmat(rhs(:), [1 obj.m_ndd]);
      obj.m_derivs = subsasgn(obj.m_derivs, dind, rhs);
      obj.m_derivs = reshape(obj.m_derivs, [numel(testobj) obj.m_ndd]);
      obj.m_size = computeSize(obj);
    end
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
% $Id: subsasgn_old.m 4196 2014-05-14 18:01:32Z willkomm $
