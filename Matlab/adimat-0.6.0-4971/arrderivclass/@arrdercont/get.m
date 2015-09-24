% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function val = get(obj, name)
  % if iscell(name)
  %   val = admGetDDs(obj, name{1});
  %   return
  % end
  switch name
   case 'direct'
    dirs = cell(obj.m_ndd, 1);
    for i=1:obj.m_ndd
      dirs{i} = admGetDD(obj, i);
    end
    val = [dirs{:}];
   case 'ndd'
    val = obj.m_ndd;
   case 'size'
    val = obj.m_size;
   case 'deriv'
    val = obj.m_derivs;
   otherwise
    val = option(name);
  end
end
% $Id: get.m 4542 2014-06-14 21:06:10Z willkomm $
