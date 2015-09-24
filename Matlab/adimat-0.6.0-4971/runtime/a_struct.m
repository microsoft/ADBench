% function r = a_zeros_index(adjArrayVar, arrayVar, index1, ...)
%   Zero adjoint of index expression after assignment. If the forward
%   assignment changed the size of the array variable, then maybe
%   resize the adjoint here, undoing the size change.  If the size did
%   not change then fill the indexed adjoint with a_zeros.
%
% see also a_zeros, adimat_push_field, adimat_pop_field
%
% This file is part of the ADiMat runtime environment
%
function varargout = a_struct(varargin)
  for i=1:nargin
    % FIXME: the following does not work in octave 3.0 (it does in 3.2)
    res = repmat(struct(), size(varargin{i}));
    fns = fieldnames(varargin{i});
    for k=1:length(fns)
      fields = {varargin{i}.(fns{k})};
      [res.(fns{k})] = a_zeros(fields{:});
    end
    varargout{i} = res;
  end
 
% $Id: a_struct.m 3166 2012-02-27 13:28:35Z willkomm $
