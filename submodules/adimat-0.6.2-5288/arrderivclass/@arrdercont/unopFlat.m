% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = unopFlat(obj, handle, varargin)
  obj.m_derivs = handle(obj.m_derivs);
end
% $Id: unopFlat.m 3862 2013-09-19 10:50:56Z willkomm $
