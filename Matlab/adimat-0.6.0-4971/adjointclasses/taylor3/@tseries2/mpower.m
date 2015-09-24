function obj = mpower(obj, right)
  if isscalar(obj) && isscalar(right)
    obj = power(obj, right);
  else
    if isscalar(obj)
      obj = adimat_mpower(obj, right)
    else
      error('adimat:tseries2:mpower:unsupportedArguments', '%s',...
            ['For mpower, the case matrix^scalar ' ...
             'are not yet supported by the tseries2 class.']);
    end
  end
end
