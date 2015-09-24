% function r = adimat_stack_byte_size()
%  return the size of the stack in bytes, if that measure is
%  available, otherwise 0
%
% see also adimat_store, adimat_stack, adimat_clear_stack,
% adimat_size, adimat_file_size
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_byte_size()
  r = adimat_store(4, 0);

% $Id: adimat_stack_byte_size.m 3384 2012-09-01 16:27:47Z willkomm $
