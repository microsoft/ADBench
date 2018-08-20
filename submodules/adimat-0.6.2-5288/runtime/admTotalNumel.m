% function nels = admTotalNumel(varargin)
%
% Computes sum of prod(size(.)) of each argument. It does not use
% numel, because this has a different meaning for derivative classes.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function nels = admTotalNumel(varargin)
  isnum = cellfun(@isnumeric, varargin);
  nels = sum(cellfun('prodofsize', varargin(isnum)));
  iscs = cellfun(@iscell, varargin) | cellfun(@isstruct, varargin);
  for c=find(iscs)
    obj = varargin{c};
    if iscell(obj)
      nels = nels + admTotalNumel(obj{:});
    elseif isstruct(obj)
      fns = fieldnames(obj);
      for i=1:length(fns)
        fields = {obj.(fns{i})};
        nels = nels + admTotalNumel(fields{:});
      end
    end
  end
% $Id: admTotalNumel.m 4405 2014-06-03 11:20:22Z willkomm $
