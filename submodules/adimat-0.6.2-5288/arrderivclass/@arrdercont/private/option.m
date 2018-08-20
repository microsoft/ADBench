function r = option(name, val)
  persistent global_ndd global_inner
  if nargin < 2
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      r = global_ndd;
     case {'inner'}
      if isempty(global_inner)
        global_inner = @double;
      end
      r = global_inner;
     case 'Version'
      r = adimat_version();
     case 'DerivativeClassVersion'
      r = 0.81;
     case 'DerivativeClassName'
      r = 'arrdercont';
     case 'DerivativeClassKind'
      r = 'array';
     case 'ClearAll'
      global_ndd = [];
      global_inner = [];
      r = [];
     otherwise
      error('cannot get invalid option name %s', name);
      r = sprintf('unknown field %s', name);
    end
  else
    r = [];
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      global_ndd = val;
     otherwise
      error('cannot set invalid option name %s', name);
    end
  end
end
% $Id: option.m 4722 2014-09-19 11:42:25Z willkomm $
