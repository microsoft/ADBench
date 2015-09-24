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
  if (ischar(varargin{1}) && (varargin{1}==':'))
    res = obj.m_ndd(1);
  else
    res = length(varargin{1});
  end
%  fprintf('arrdercont.numel: %d\n', res);
end
% $Id: numel.m 3862 2013-09-19 10:50:56Z willkomm $
