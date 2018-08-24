%
% function adj = a_rmfield(adj, varargin)
%   compute adjoint of rmfield(val, varargin{:})
%
% see also a_mean, a_repmat
%
% This file is part of the ADiMat runtime environment
%
function adj = a_rmfield(adj, val, names)
  
  if iscell(names)
    for i=1:length(names)
      name = names{i};
      for k=1:numel(val)
        adj(k).(name) = a_zeros(val(k).(name));
      end
    end
  else
    for k=1:numel(val)
      adj(k).(names) = a_zeros(val(k).(names));
    end
  end
  
% $Id: a_rmfield.m 2070 2010-07-14 16:00:51Z willkomm $
