% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function val = toDouble(obj)
  if isobject(obj.m_derivs{1})
    nsz = [1 size(toDouble(obj.m_derivs{1}))];
    vals = cellfun(@(x) reshape(toDouble(x), nsz), obj.m_derivs, 'UniformOutput', false);
  else
    nsz = [1 size(obj.m_derivs{1})];
    vals = cellfun(@(x) reshape(x, nsz), obj.m_derivs, 'UniformOutput', false);
  end
  val = cat(1, vals{:});
end
% $Id: toDouble.m 3862 2013-09-19 10:50:56Z willkomm $
