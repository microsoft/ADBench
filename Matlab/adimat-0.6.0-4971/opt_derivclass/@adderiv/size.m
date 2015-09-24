function [varargout] = size(g, varargin)
%ADDERIV/SIZE Get the size of object that the derivative is associated with.
%
%  sz = size(g); Gets the 0-th directional derivative of the 
%       first order derivative object g and returns the size of it.
%       
%       This means that size(g_x) has the same result as size(x).
%
% see also adderiv/numel adderiv/length
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!
%
  if isempty(g.deriv)
    [varargout{1:nargout}] = size([], varargin{:});
  else
    [varargout{1:nargout}] = size(g.deriv{1,1}, varargin{:});
  end
end

