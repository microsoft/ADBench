% function varargout = a_zeros(varargin)
%
% Create zero adjoints. This function creates zero derivative objects
% of the current derivative class selected with adimat_derivclass, by
% calling the function g_zeros. These adjoints are used in vector
% reverse mode.
%
% see also g_zeros, adimat_derivclass, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
function varargout = a_zeros(varargin)
  varargout = cell(nargin, 1);
  for i=1:nargin
    c = varargin{i};
    if iscell(c)
      rc = cell(size(c));
      [rc{:}] = a_zeros(c{:});
      varargout{i} = rc;
    elseif isstruct(c)
      varargout{i} = a_struct(c);
    else
      varargout{i} = tay_zeros(c);
    end
  end
     
% $Id: a_zeros.m 4391 2014-05-30 14:39:26Z willkomm $
