% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = calln(handle, varargin)
  if ismember(func2str(handle), methods(varargin{1}))
    obj = handle(varargin{:});
  else
    nparm = nargin-1;
    tmpc = cell(nparm, 1);
    obj = arrdercont(varargin{1});
    % first iteration, unrolled
    for k=1:nparm
      tmpc{k} = admGetDD(varargin{k}, 1);
    end
    dd = handle(tmpc{:});
    obj.m_size = size(dd);
    obj.m_derivs = zeros(prod(obj.m_size), obj.m_ndd);
    obj.m_derivs(:,1) = dd(:);
    for i=2:obj.m_ndd
      for k=1:nparm
        tmpc{k} = admGetDD(varargin{k}, i);
      end
      dd = handle(tmpc{:});
      obj.m_derivs(:,i) = dd(:);
    end
  end
end
% $Id: calln.m 4507 2014-06-13 13:47:38Z willkomm $
