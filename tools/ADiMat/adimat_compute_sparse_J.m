function [Jacobian, fval] = adimat_compute_sparse_J(diffFunction, funcArgs,...
    fNargout, independents, nzpattern, coloring, compressedSeedMatrix)

if nargin < 6
    colFunc = @cpr;
    [colResults{1:2}] = colFunc(nzpattern);
    coloring = colResults{2};
    compressedSeedMatrix = admCreateCompressedSeedSparse(coloring);
end
        
dependents = 1:fNargout;
nActResults = length(dependents);

if ~strcmp(adimat_derivclass, 'vector_directderivs')
    adimat_derivclass('vector_directderivs');
end

nActArgs = numel(independents);
[dargs{1:nActArgs}] = createSeededGradientsFor(compressedSeedMatrix, funcArgs{independents});

dfargs = admMergeArgs(dargs, funcArgs, independents);

nDFResults = fNargout + nActResults;
[output{1:nDFResults}] = diffFunction(dfargs{:});

actOutIndices = admDerivIndices(dependents);
nactOutIndices = admNDerivIndices(fNargout, dependents);

dResults = {output{actOutIndices}};
Jacobian = admJacFor(dResults{:});

seedW = 1;
Jacobian = admUncompressJac(Jacobian, nzpattern, coloring, seedW);

fval = output(nactOutIndices);