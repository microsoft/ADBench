function varargout = svd(obj)
  [varargout{1:nargout}] = adimat_svd(obj);
end
