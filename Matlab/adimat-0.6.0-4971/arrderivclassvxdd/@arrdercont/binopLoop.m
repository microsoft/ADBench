% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = binopLoop(obj, right, handle)
  if isa(obj, 'arrdercont')
    if isa(right, 'arrdercont')
      if obj.m_ndd > 0
        dd1 = reshape(obj.m_derivs(:,1), obj.m_size);
        dd2 = reshape(right.m_derivs(:,1), right.m_size);
        dd = handle(dd1, dd2);
        res = arrdercont(dd);
        res.m_derivs(:,1) = dd(:);
        for i=2:obj.m_ndd
          dd1 = reshape(obj.m_derivs(:,i), obj.m_size);
          dd2 = reshape(right.m_derivs(:,i), right.m_size);
          dd = handle(dd1, dd2);
          res.m_derivs(:,i) = dd(:);
        end
      else
        dd1 = zeros(obj.m_size);
        dd2 = zeros(right.m_size);
        res = arrdercont(handle(dd1, dd2));
      end
    else
      if obj.m_ndd > 0
        dd1 = reshape(obj.m_derivs(:,1), obj.m_size);
        dd = handle(dd1, right);
        res = arrdercont(dd);
        res.m_derivs(:,1) = dd(:);
        for i=2:obj.m_ndd
          dd1 = reshape(obj.m_derivs(:,i), obj.m_size);
          dd = handle(dd1, right);
          res.m_derivs(:,i) = dd(:);
        end
      else
        dd1 = zeros(obj.m_size);
        dd2 = zeros(right.m_size);
        res = arrdercont(handle(dd1, dd2));
      end
    end
  else
    if obj.m_ndd > 0
      val = obj;
      obj = right;
      dd2 = reshape(obj.m_derivs(:,1), obj.m_size);
      dd = handle(val, dd2);
      res = arrdercont(dd);
      res.m_derivs(:,1) = dd(:);
      for i=2:obj.m_ndd
        dd2 = reshape(obj.m_derivs(:,i), obj.m_size);
        dd = handle(val, dd2);
        res.m_derivs(:,i) = dd(:);
      end
    else
      dd1 = zeros(obj.m_size);
      dd2 = zeros(right.m_size);
      res = arrdercont(handle(dd1, dd2));
    end
  end
end
% $Id: binopLoop.m 4385 2014-05-30 10:57:45Z willkomm $
