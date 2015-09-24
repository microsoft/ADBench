% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function val = get(obj, name)
  switch name
   case 'direct'
    dirs = cell(obj.m_ndd, 1);
    for i=1:obj.m_ndd
      dirs{i} = admGetDD(obj, i);
    end
    val = [dirs{:}];
   case 'size'
    val = size(obj);
   case 'deriv'
    val = obj.m_derivs;
   otherwise
    val = option(name);
  end
end
% $Id: get.m 4200 2014-05-15 07:47:59Z willkomm $
