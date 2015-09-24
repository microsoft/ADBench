% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function varargout = callm(handle, varargin)

  nin= nargin-1;
  inp= cell(nin, 1);
  outp= cell(nargout, 1);

  obj = varargin{1};
  
  for i=1:obj.m_ndd
    for k=1:nin
      inp{k} = admGetDD(varargin{k}, i);
    end

    [outp{:}] = handle(inp{:});
    
    if i == 1
      for k=1:nargout
        varargout{k} = arrdercont(outp{k});
        varargout{k} = admSetDD(varargout{k}, i, outp{k});
      end
    else
      for k=1:nargout
        varargout{k} = admSetDD(varargout{k}, i, outp{k});
      end
    end

  end
end
% $Id: callm.m 4533 2014-06-14 20:57:59Z willkomm $
