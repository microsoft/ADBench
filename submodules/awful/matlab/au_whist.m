function h = au_whist(i, weights, imax)
% AU_WHIST   Weighted histogram
%           H = AU_WHIST(I, WEIGHTS, IMAX);
%           is the same as H = full(sparse(1, I, WEIGHTS, 1, IMAX));
%           but much faster.
error('need mex');
