% function z = admCanonFDMethodName(meth)
%
% Canonicalize the alias names for the three FD methods central,
% forward, and backward.
%
% see also admDiffFD, admOptions.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function z = admCanonFDMethodName(meth)
  z = '';
  switch meth
   case {'c', 'central', 'centered', 'centralized'}
    z = 'central';
   case {'l', 'left', 'neg', 'negative', 'b', 'back', 'backward', 'backwards'}
    z = 'backward';
   case {'r', 'right', 'pos', 'positive', 'f', 'for', 'forward', 'forwards'}
    z = 'forward';
   otherwise
    error('adimat:admCanonFDMethodName:unknownFDMode', ...
          'FD method name "%s" is unknown', meth)
  end
end
% $Id: admCanonFDMethodName.m 3066 2011-10-08 19:59:05Z willkomm $
