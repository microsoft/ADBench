% function [r] = adimat_norm1(x)
%  
% Compute r = norm(x), for AD.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [r] = adimat_norm1(x)

  p= 2; % default case

  r = adimat_norm2(x, p);

end

% $Id: adimat_norm1.m 3738 2013-06-12 16:48:53Z willkomm $

