function r = option(name, val)
  persistent options
  if isempty(options)
    options = struct('ord', 1, 'inner', @arrdercont);
  end
  if nargin < 2
    switch name
     case 'options'
      r = options;
     case 'maxorder'
      r = options.ord;
     case 'inner'
      r = options.inner;
     case {'DerivativeClassVersion'}
      r = 0.112;
     case {'DerivativeClassName'}
      r = 'tseries2';
     case {'DerivativeClassKind'}
      r = 'tseries';
     otherwise
      error('unknown field %s', name);
    end
  else
    switch name
     case {'maxorder'}
      options.ord = val;
     case {'inner'}
      options.inner = val;
    end
  end
end
