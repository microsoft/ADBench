function [seedV seedW seedRev compressedSeed coloring] = admMakeUserSeedMatricesHess(seedMatrix, admOpts)
  [seedV seedW seedRev] = admUnpackUserSeedMatricesHess(seedMatrix, admOpts);
  if ~isempty(admOpts.JPattern)
    [compressedSeed coloring] = admMakeSeedMatrixFor(seedW, admOpts.x_nCompInputs, admOpts);
  else
    compressedSeed = seedW;
    coloring = [];
  end
end
