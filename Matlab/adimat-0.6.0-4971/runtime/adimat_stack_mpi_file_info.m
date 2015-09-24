% function r = adimat_stack_mpi_file_info(s)
%
% Set the MPI_Info fields used for opening the MPI_File.
%
% see also admMPIFileInfo, admStackOptions, admOptions
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_mpi_file_info(s)
  r = true;
  fns = fieldnames(s);
  for i=1:length(fns)
    name = fns{i};
    value = s.(name);
    envVarName = sprintf('MPI_File_Info_%s', name);
    if isa(value, 'char')
      envVarValue = value;
    else
      envVarValue = sprintf('%g', value);
    end
    setenv(envVarName, envVarValue);
  end
end

% $Id: adimat_stack_mpi_file_info.m 3382 2012-08-31 11:11:11Z willkomm $
