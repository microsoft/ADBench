% function [dpp] = adimat_pder(pp)
%   
% Create struct of differentiated piecewise polynomials, given struct
% describing piecewise differentiated polynomials, as generated for
% example by interp1(..., 'pp').
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function dpp = adimat_ppder(pp)
  dpp = pp;
  dpp.order = pp.order - 1;
  dpp.coefs = pp.coefs(:,1:end-1);
  for i=1:size(pp.coefs,1)
    dc = polyder(pp.coefs(i,:));
    l = length(dc);
    dpp.coefs(i,end-l+1:end) = dc;
  end
% $Id: adimat_ppder.m 3657 2013-05-22 16:39:59Z willkomm $
