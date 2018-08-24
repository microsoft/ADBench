% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function disp(obj)
  fprintf('N-Times wrapper with %d directions of size %s\n', obj.m_ndd, ...
          mat2str(size(obj)));
  for i=1:obj.m_ndd
    fprintf('Direction %d:\n', i);
    disp(admGetDD(obj, i));
  end
end
% $Id: disp.m 3862 2013-09-19 10:50:56Z willkomm $
