
[adimathome name stem] = fileparts(mfilename('fullpath'));

setenv('ADIMAT_HOME', adimathome);

if ispc
  adimat_prefix = adimathome;
  pathsep = ';';
else
  adimat_prefix = fullfile(adimathome, 'share', 'adimat');
  pathsep = ':';
end

setenv('PATH', [getenv('PATH') pathsep fullfile(adimathome, 'bin')]);

addpath(fullfile(adimat_prefix, 'runtime'))

adimat_derivclass arrderivclass;

adimat_adjoint default;

adimat_stack native-cell;

clear adimathome name stem adimat_prefix pathsep
