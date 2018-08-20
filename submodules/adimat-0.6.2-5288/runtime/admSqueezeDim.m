function H = admSqueezeDim(H, dim)
  if nargin < 2
    dim = 1;
  end
  if size(H,dim) == 1
    hsz = size(H);
    hsz(dim) = [];
    if length(hsz) < 2
      hsz(end+1) = 1;
    end
    H = reshape(H, hsz);
  end
