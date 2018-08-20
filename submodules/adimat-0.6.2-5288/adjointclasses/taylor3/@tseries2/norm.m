function r = norm(obj, varargin)
  if nargin < 2
    p = 2;
  else
    p = varargin{1};
  end
  r = adimat_norm2(obj, p);
end
