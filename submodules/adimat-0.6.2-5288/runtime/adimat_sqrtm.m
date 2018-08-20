% function [R U T] = adimat_sqrtm(x)
%
% Compute z = sqrtm(x). This uses a schur method as described in "A
% Schur method for the Square Root of a Matrix", Åke Björck, 1982. 
% 
% This function is differentiation with ADiMat to create the runtime
% functions g_adimat_sqrtm, d_adimat_sqrtm, and a_adimat_sqrtm.
%
% see also g_adimat_sqrtm, d_adimat_sqrtm, and a_adimat_sqrtm.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [R U T] = adimat_sqrtm(x)

  [U T] = adimat_schur(x);
%  [U T] = schur(x, 'complex');
%  squal = norm(U * T * U' - x)

  R = adimat_sqrtm_triu(T);
  
  R = U * R * U';
%  squal = norm(R * R - x)
end
% $Id: adimat_sqrtm.m 3821 2013-07-16 08:55:22Z willkomm $
