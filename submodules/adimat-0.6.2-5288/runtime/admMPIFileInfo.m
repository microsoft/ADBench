% function r = admMPIFileInfo(name1, val1, name2, val2, ...)
%
% Create structure with fields determining stack options. The default
% structure has no fields.
%
% see also admOptions, admStackOptions, adimat_stack_mpi_file_info, admDiffRev
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = admMPIFileInfo(varargin)
  r = struct();

  for i=2:2:nargin
    name = vargargin{i-1};
    val = vargargin{i};
    r.(name) = val;
  end
  
  if ~isempty(fieldnames(r))
    r = orderfields(r);
  end
% $Id: admMPIFileInfo.m 3391 2012-09-05 23:44:54Z willkomm $
