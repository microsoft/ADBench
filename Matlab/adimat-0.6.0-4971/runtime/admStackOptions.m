% function r = admStackOptions(name1, val1, name2, val2, ...)
%
% Create structure with fields determining stack options. This is the
% field 'stack' of admOptions. It is given to the function
% adimat_setup_stack. The arguments are alternating names and values
% and are used to set initially fields of the structure.
%
% The default field values are:
%
% r.bufferSize = 2^30;               % 1 GB
% r.numBuffers = 16;
% r.aio_threads = [];                % default: numBuffers
% r.aio_num = [];                    % default: numBuffers
% r.aio_idle_time = [];              % default: 10 
% r.odirect = [];                    % default: 0
% r.prefetchBlocks = [];
% r.verbose = 1;
% r.mpiFileInfo = admMPIFileInfo();
% r.asyncIOType = '';                % default: mb_mpio
% r.name = '';                       % default: no change
% r.infoStackName = '';              % default: no change
% r.dirName = '';                    % default: $TMP
% r.fileName = '';                   % default: generated name containing hostname and PID
%
% see also adimat_setup_stack, adimat_stack, admOptions, admDiffRev
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2014 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = admStackOptions(varargin)
r = struct('admstackopts', 1, ...
           'aio_idle_time', [
   ], ...
           'aio_num', [
   ], ...
           'aio_threads', [
   ], ...
           'asyncIOType', '', ...
           'bufferSize', 1073741824, ...
           'dirName', '', ...
           'fileName', '', ...
           'infoStackName', '', ...
           'mpiFileInfo', struct(), ...
           'name', '', ...
           'numBuffers', 16, ...
           'odirect', [
   ], ...
           'prefetchBlocks', [
   ], ...
           'verbose', 1);
  for i=2:2:nargin
    name = vargargin{i-1};
    val = vargargin{i};
    if ~isfield(r, name)
      warning('adimat:admStackOptions:unknownField', ...
              'admStackOptions structure does not have a field named "%s"', name);
    end
    r.(name) = val;
  end
  
  r = orderfields(r);
% $Id: admStackOptions_code.m 4254 2014-05-19 07:30:21Z willkomm $
