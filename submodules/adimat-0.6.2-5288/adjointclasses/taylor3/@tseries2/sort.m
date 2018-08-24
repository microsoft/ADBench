function [obj P] = sort(obj, varargin)
  [obj.m_series{1} P] = sort(obj.m_series{1}, varargin{:});
  if nargin < 2 || ischar(varargin{1})
    dim = adimat_first_nonsingleton(obj.m_series{1});
  else
    dim = varargin{1};
  end
  gP = mk1dperm(P, dim);
  for k=2:obj.m_ord
    obj.m_series{k} = obj.m_series{k}(gP);
  end
end
% $Id: sort.m 4981 2015-05-11 08:26:05Z willkomm $
