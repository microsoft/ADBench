% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = numel(obj, varargin)
%  fprintf('arrdercont.numel: %s\n', num2str(size(obj)));
%  disp(varargin);
  if nargin < 2
    res = 1;
    return
  end
  s = varargin{1};
  tinfo = whos('s');
  if strcmp(tinfo.class, 'magic-colon') || (ischar(varargin{1}) && (varargin{1}==':'))
    res = obj.m_ndd(1);
  else
    res = length(varargin{1});
  end
%  fprintf('arrdercont.numel: %d\n', res);
end
% $Id: numel.m 4686 2014-09-18 09:59:43Z willkomm $
