% function r = adimat_store(mode, v)
%
% This function implements adimat_push and adimat_pop, which are
% required by the reverse mode source code. The function admDiffRev is
% the driver for the reverse mode in ADiMat.
%
% The function takes two arguments: a mandatory mode and a value v. v
% is required when mode = 1, otherwise not. The bahaviour depends on
% mode, as follows.
%
%   mode=0: pop value from stack
%   mode=1: store value v on stack
%   mode=2: clear stack
%   mode=3: query stack size
%   mode=4: query reserved stack size
%   mode=5: flush the stack (N/A)
%   mode=6: return the file size of the stack (N/A)
%   mode=7: return the entire stack
%
% There are different implementations of adimat_store. These can be
% selected manually using the function adimat_stack. The driver
% function admDiffRev, uses the value of the field stack in
% admOptions.
%
% see also adimat_push, adimat_pop, adimat_clear_stack,
%  adimat_stack_size, adimat_stack, admDiffRev.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University

% $Id: adimat_store_help.txt 3385 2012-09-03 12:41:29Z willkomm $
% Local Variables:
% mode: matlab
% End:
