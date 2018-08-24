% function varargout = a_zeros(varargin)
%
% Create zero adjoints. This function creates zero derivatives of
% class double, by calling the function zeros. These adjoints are used
% in scalar reverse mode.
%
% see also zeros, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
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
      varargout{i} = zeros(size(c));
    end
  end
     
% $Id: a_zeros.m 4175 2014-05-13 15:06:54Z willkomm $
