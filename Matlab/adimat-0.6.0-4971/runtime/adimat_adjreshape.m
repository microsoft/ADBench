%
% function r = adimat_adjreshape(val, adj)
%   This determines the adjoint value of val, given as parameter adj.
%
%   If val is a scalar return adj,
%   otherwise return adj, reshaped to size(val), if necessary.
%
% see also adimat_adjred
%
% This file is part of the ADiMat runtime environment
%
function adj = adimat_adjreshape(val, adj)
  sz = size(val);
  if ~isscalar(val)
 %   if ~isequal(adjSz, sz)
 %     warning('adimat:runtime:adjreshape', 'wrong sizes: value %dx%d adjoint %dx%d', ...
 %             sz(1), sz(2), adjSz(1), adjSz(2));
      adj = reshape(adj, sz);
 %   end
  end

% $Id: adimat_adjreshape.m 3153 2011-12-30 19:27:54Z willkomm $
