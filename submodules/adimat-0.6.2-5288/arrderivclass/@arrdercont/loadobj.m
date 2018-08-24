function s = loadobj(s)
  if ~isa(s, 'arrdercont')
    s = class(s, 'arrdercont');
  end
  set(s, 'NumberOfDirectionalDerivatives', s.m_ndd);
end
