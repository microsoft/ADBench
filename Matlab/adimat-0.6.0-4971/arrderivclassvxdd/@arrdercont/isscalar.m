function r = isscalar(obj)
  r = prod(obj.m_size) == 1;
end
