function [varargout] = size(g, k)
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
  if nargin == 1
    if nargout > 1
      for i=1:nargout
        varargout{i} = g.sz(i);
      end
      varargout{i+1} = prod(g.sz(i:end));
    else
      varargout{1} = g.sz;
    end
  else
    varargout{1} = g.sz(k);
  end
end

% $Id: size.m 2926 2011-05-21 12:18:59Z willkomm $
