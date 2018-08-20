% function varargout = d_struct(varargin)
%   Create zero derivative object of struct objects
%
% see also d_zeros, a_struct
%
% This file is part of the ADiMat runtime environment
%
function varargout = d_struct(varargin)
  for i=1:nargin
    res = repmat(struct(), size(varargin{i}));
    fns = fieldnames(varargin{i});
    for k=1:length(fns)
      firstField = varargin{i}(1).(fns{k});
      if isfloat(firstField) || isstruct(firstField) || iscell(firstField)
        fields = {varargin{i}.(fns{k})};
        [res.(fns{k})] = d_zerosv(fields{:});
      end
    end
    varargout{i} = res;
  end
 
% $Id: d_struct.m 2997 2011-06-21 15:30:11Z willkomm $
