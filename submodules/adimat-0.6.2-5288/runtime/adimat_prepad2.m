% function r = adimat_prepad(a,l,c)
%
% Mimic the function prepad, which is available in Octave, but not in MATLAB
%
% (c) 2018 Johannes Willkomm
function r = adimat_prepad2(a,l)
  r = adimat_prepad(a,l,0,adimat_first_nonsingleton(a));
