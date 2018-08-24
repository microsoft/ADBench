% function F = d_eig_F(d)
%
% Compute matrix F needed in differentitation of eig.
%
% see also a_eig11, a_eig21, a_eig22
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function F = d_eig_F(d)
  
  n = length(d);
  
  p1 = repmat(d.', [n, 1]); 
  p2 = repmat(d,   [1, n]);

  F = p1 - p2; 

  neqz = F ~= 0;
  F(neqz) = 1 ./ F(neqz);
  
  F(diag(true(n, 1))) = 0;
  
% $Id: d_eig_F.m 3966 2013-10-31 13:04:34Z willkomm $
