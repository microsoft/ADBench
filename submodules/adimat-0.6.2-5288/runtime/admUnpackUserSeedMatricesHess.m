function [seedV seedW seedRev] = admUnpackUserSeedMatricesHess(seedMatrix, admOpts)
  if iscell(seedMatrix)
    if numel(seedMatrix) == 2
      seedRev = seedMatrix{1};
      seedV = 1;
      seedW = seedMatrix{2};
    elseif numel(seedMatrix) == 3
      seedRev = seedMatrix{1};
      seedV = seedMatrix{2};
      seedW = seedMatrix{3};
    else
      error('if seed matrix argument is a cell, it must have 2 or 3 components');
    end
  else
    seedV = 1;
    seedW = seedMatrix;
    seedRev = admOpts.seedRev;
  end
end
