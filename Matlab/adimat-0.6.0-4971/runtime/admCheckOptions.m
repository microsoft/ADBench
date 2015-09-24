% function [r ill] = admCheckOptions(opts, ref)
%
% Check admOptions fields for invalid field names.
%
% see also admOptions, admStackOptions, admTransformParameters
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function [r ill] = admCheckOptions(opts, ref, name)
  if nargin < 2
    ref = admOptions;
    name = 'admOptions';
  end
  d = setdiff(fieldnames(opts), fieldnames(ref));
  h = strncmp(d, 'x_', 2);
  ill = d(~h);
  if ~isempty(ill)
    for i=1:length(ill)
      warning('adimat:admCheckOptions:illegalOptionsField', ...
              ['the %s struct has an illegal field: "%s". User defined ' ...
               'fields must begin with prefix "x_".'], name, ill{i});
    end
  end
  if isfield(opts, 'admopts')
    admCheckOptions(opts.stack, admStackOptions, [name '.stack']);
    admCheckOptions(opts.parameters, admTransformParameters, [name '.parameters']);
  
    if ~isa(opts.hessianStrategy, 'char')
      error('adimat:admHessian:illegalHessianStrategy',...
            'The value for options field hessianStrategy has an invalid type: %s. It must be char.',...
            class(hStrat));
    end
  
    if ~isempty(opts.dependents)
      if ~isrow(opts.dependents)
        error('adimat:options:invalidArgumentIndex', ...
              '%s', ...
              'The options field dependents must be a row array (or empty).');
      end
      if ~isequal(opts.dependents, unique(opts.dependents))
        error('adimat:options:invalidArgumentIndexValues', ...
              '%s', ...
              'The options field dependents must have unique integer values.');
      end
    end
    if ~isempty(opts.independents)
      if ~isrow(opts.independents)
        error('adimat:options:invalidArgumentIndex', ...
              '%s', ...
              'The options field independents must be a row array (or empty).');
      end
      
      if ~isequal(opts.independents, unique(opts.independents))
        error('adimat:options:invalidArgumentIndexValues', ...
              '%s', ...
              'The options field independents must have unique integer values.');
      end
    end

  end
  r = true;

% $Id: admCheckOptions.m 4516 2014-06-13 15:05:37Z willkomm $
