function der = getder(obj, dim)
  der = reshape(obj.m_derivs, [obj.m_size, ones(1,dim-length(obj.m_size)), obj.m_ndd]);
