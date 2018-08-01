function au_mexall
% AU_MEXALL  Mex all files in awful.
d = cd;
[newdir,~,~] = fileparts(mfilename('fullpath'));

o = onCleanup(@(x) cd(d));

cd(newdir)

domex -I. au_quat2mat.cxx
domex -I. au_rodrigues_mex.cxx
domex -largeArrayDims au_sparse.cxx
domex au_whist.cxx
domex au_deep_vectorize_mex.cxx
domex au_deep_unvectorize_mex.cxx

function domex(varargin)
disp(au_reduce(@(x,y) [x ' ' y], varargin, 'mex'))
mex(varargin{:})
