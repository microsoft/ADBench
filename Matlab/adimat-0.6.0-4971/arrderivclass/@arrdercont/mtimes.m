% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = mtimes(obj, right)
  if isscalar(obj) || isscalar(right)
    res = times(obj, right);
  else
    % pref = getpref('adimat', 'optimizeloopthreshold', 0.9);
    if isobject(obj)
      if isobject(right)
        pref = 1.1;
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn x %dndd)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2), right.m_ndd);
        if obj.m_size(1) < obj.m_ndd.*pref || right.m_size(2) < obj.m_ndd.*pref
          res = arrdercont(obj);
          res.m_size = [obj.m_size(1) right.m_size(2)];
          res.m_derivs = zeros([obj.m_ndd res.m_size]);
          if obj.m_size(1) < right.m_size(2).*0.9
            for k=1:obj.m_size(1)
              ddr = bsxfun(@times, reshape(obj.m_derivs(:,k,:), [obj.m_ndd obj.m_size(2)]), right.m_derivs);
              res.m_derivs(:,k,:) = sum(ddr, 2);
            end
          else
            for k=1:right.m_size(2)
              ddr = bsxfun(@times, obj.m_derivs, reshape(right.m_derivs(:,:,k), [obj.m_ndd 1 right.m_size(1)]));
              res.m_derivs(:,:,k) = sum(ddr, 3);
            end
          end
        else
          res = binopLoop(obj, right, @mtimes);
        end
      else
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2));
        res = arrdercont(obj);
        res.m_size = [obj.m_size(1) size(right, 2)];
        res.m_derivs = reshape(reshape(obj.m_derivs, [obj.m_ndd.*obj.m_size(1) obj.m_size(2)]) * right,...
                               [res.m_ndd res.m_size]);
      end
    else
%      fprintf(admLogFile, 'mtimes: (%dm x %dn) * (%dm x %dn x %dndd)\n',...
%              size(obj,1), size(obj,2), size(right,1), size(right,2), right.m_ndd);
      pref = 50;
      if right.m_size(2) < right.m_ndd.*pref
        res = arrdercont(right);
        res.m_size = [size(obj, 1) right.m_size(2)];
        res.m_derivs = zeros([right.m_ndd res.m_size]);
        ot = obj.';
        for k=1:right.m_size(2)
          ddr = right.m_derivs(:,:,k) * ot;
          res.m_derivs(:,:,k) = ddr;
        end
      else
        res = binopLoop(obj, right, @mtimes);
      end
    end
  end
end
% $Id: mtimes.m 4358 2014-05-28 11:13:35Z willkomm $
